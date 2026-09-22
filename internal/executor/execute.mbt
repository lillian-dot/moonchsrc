///|
/// Capture the currently effective source values before a mutation.
async fn capture_snapshot(plan : @moonchsrc.ChangePlan) -> @moonchsrc.Snapshot {
  let get_plan = @moonchsrc.plan_get(plan.target_id, scope=plan.scope)
  let values : Array[@moonchsrc.SavedValue] = []
  for command in get_plan.commands {
    let (exit_code, stdout, _) = @process.collect_output(
      command.program,
      command.args,
      no_console_window=true,
    )
    values.push(
      @moonchsrc.capture_command_value(plan.target_id, exit_code, stdout.text()),
    )
  }
  for step in get_plan.file_steps {
    let resolved = resolve_path(step.path)
    if @fs.exists(resolved.path) {
      values.push(
        @moonchsrc.capture_config_file(@fs.read_file(resolved.path).text()),
      )
    } else {
      values.push(Missing)
    }
  }
  {
    target_id: plan.target_id,
    scope: plan.scope,
    values,
    captured_at: @env.now(),
  }
}

///|
priv struct ResolvedPath {
  directory : String
  path : String
}

///|
fn resolve_path(path : @moonchsrc.ConfigPath) -> ResolvedPath {
  match path {
    CargoProject => { directory: ".cargo", path: ".cargo/config.toml", }
    CargoUser => {
      let directory = match @env.get_env_var("CARGO_HOME") {
        Some(root) => root
        None =>
          match @env.get_env_var("USERPROFILE") {
            Some(root) => "\{root}/.cargo"
            None =>
              match @env.get_env_var("HOME") {
                Some(root) => "\{root}/.cargo"
                None => ".cargo"
              }
          }
      }
      { directory, path: "\{directory}/config.toml", }
    }
    MoonUser => {
      let directory = match @env.get_env_var("MOON_HOME") {
        Some(root) => root
        None =>
          match @env.get_env_var("USERPROFILE") {
            Some(root) => "\{root}/.moon"
            None =>
              match @env.get_env_var("HOME") {
                Some(root) => "\{root}/.moon"
                None => ".moon"
              }
          }
      }
      { directory, path: "\{directory}/config.json", }
    }
  }
}

///|
fn is_windows() -> Bool {
  @env.get_env_var("OS") == Some("Windows_NT")
}

///|
async fn write_atomic(resolved : ResolvedPath, content : String) -> Unit {
  if !@fs.exists(resolved.directory) {
    @fs.mkdir(resolved.directory, recursive=true)
  }
  let temporary = "\{resolved.path}.moonchsrc-\{@env.now()}.tmp"
  @fs.write_file(temporary, content)
  if !is_windows() {
    @fs.chmod(temporary, 0o600)
  }
  @fs.rename(temporary, resolved.path, replace=true)
}

///|
async fn run_file_step(step : @moonchsrc.FileStep) -> Int {
  let resolved = resolve_path(step.path)
  try {
    match step.operation {
      ReadCargoSource =>
        if !@fs.exists(resolved.path) {
          println("official (no MoonChsrc Cargo override)")
        } else {
          let content = @fs.read_file(resolved.path).text()
          match @moonchsrc.get_cargo_mirror_config(content) {
            Some(url) => println(url)
            None => println("custom/unmanaged Cargo configuration")
          }
        }
      SetCargoSource(url) => {
        let content = if @fs.exists(resolved.path) {
          @fs.read_file(resolved.path).text()
        } else {
          ""
        }
        write_atomic(resolved, @moonchsrc.set_cargo_mirror_config(content, url))
      }
      ResetCargoSource =>
        if @fs.exists(resolved.path) {
          let content = @moonchsrc.reset_cargo_mirror_config(
            @fs.read_file(resolved.path).text(),
          )
          if content.trim() == "" {
            @fs.remove(resolved.path)
          } else {
            write_atomic(resolved, content)
          }
        }
      RestoreContent(Present(content)) => write_atomic(resolved, content)
      RestoreContent(Missing) =>
        if @fs.exists(resolved.path) {
          @fs.remove(resolved.path)
        }
      RestoreContent(Redacted) => return 2
      ReadMooncakesSource =>
        if !@fs.exists(resolved.path) {
          println("official (no MoonChsrc mooncakes override)")
        } else {
          let content = @fs.read_file(resolved.path).text()
          match @moonchsrc.get_mooncakes_mirror_config(content) {
            Some(url) => println(url)
            None => println("official (no MoonChsrc mooncakes override)")
          }
        }
      SetMooncakesSource(registry~, index~, symbols~) => {
        let content = if @fs.exists(resolved.path) {
          @fs.read_file(resolved.path).text()
        } else {
          ""
        }
        write_atomic(
          resolved,
          @moonchsrc.set_mooncakes_mirror_config(
            content, registry, index, symbols,
          ),
        )
      }
      ResetMooncakesSource =>
        if @fs.exists(resolved.path) {
          let content = @moonchsrc.reset_mooncakes_mirror_config(
            @fs.read_file(resolved.path).text(),
          )
          if content == "" {
            @fs.remove(resolved.path)
          } else {
            write_atomic(resolved, content)
          }
        }
    }
    0
  } catch {
    error => {
      println("File operation failed for \{resolved.path}: \{error}")
      1
    }
  }
}

///|
async fn run_commands(commands : ArrayView[@moonchsrc.Command]) -> Int {
  for command in commands {
    let exit_code = @process.run(
      command.program,
      command.args,
      stdin=@stdio.stdin,
      stdout=@stdio.stdout,
      stderr=@stdio.stderr,
      no_console_window=true,
    )
    if exit_code != 0 {
      return exit_code
    }
  }
  0
}

///|
async fn run_plan_steps(plan : @moonchsrc.ChangePlan) -> Int {
  let command_code = run_commands(plan.commands)
  if command_code != 0 {
    return command_code
  }
  for step in plan.file_steps {
    let file_code = run_file_step(step)
    if file_code != 0 {
      return file_code
    }
  }
  0
}

///|
/// Execute a pre-resolved command directly, without invoking a shell. Mutating
/// plans first persist a credential-safe snapshot. A partial multi-command
/// failure triggers a best-effort rollback to that snapshot.
pub async fn execute(plan : @moonchsrc.ChangePlan) -> Int {
  if plan.operation == GetSource {
    return run_plan_steps(plan)
  }
  let snapshot = capture_snapshot(plan)
  if !snapshot.is_restorable() {
    println(
      "Refusing to change sources because the current configuration contains redacted credentials.",
    )
    return 2
  }
  let history_path = @history.append_default(snapshot)
  println("Saved previous source state to \{history_path}")
  let exit_code = run_plan_steps(plan)
  if exit_code == 0 {
    return 0
  }
  println("A source command failed; restoring the captured configuration...")
  let rollback = @moonchsrc.plan_restore(snapshot)
  let rollback_code = run_plan_steps(rollback)
  if rollback_code == 0 {
    println("Rollback completed.")
  } else {
    println("Rollback also failed with exit code \{rollback_code}.")
  }
  exit_code
}
