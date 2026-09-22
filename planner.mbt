///|
fn npm_command(source : Source, scope : Scope) -> Command {
  {
    program: "npm",
    args: [
      "config",
      "set",
      "registry",
      source.url,
      "--location=\{scope.to_text()}",
    ],
  }
}

///|
fn pip_command(source : Source, scope : Scope) -> Command {
  let scope_flag = match scope {
    Project => "--site"
    User => "--user"
    System => "--global"
  }
  {
    program: "python",
    args: [
      "-m",
      "pip",
      "config",
      scope_flag,
      "set",
      "global.index-url",
      source.url,
    ],
  }
}

///|
fn pnpm_command(source : Source, scope : Scope) -> Command {
  let location = match scope {
    Project => "project"
    User | System => "global"
  }
  {
    program: "pnpm",
    args: ["config", "set", "--location=\{location}", "registry", source.url],
  }
}

///|
fn yarn_command(source : Source, scope : Scope) -> Command {
  let args = ["config", "set", "npmRegistryServer", source.url]
  if scope == User {
    args.push("--home")
  }
  { program: "yarn", args, }
}

///|
fn go_command(source : Source) -> Command {
  { program: "go", args: ["env", "-w", "GOPROXY=\{source.url}"], }
}

///|
fn npm_get_command(scope : Scope) -> Command {
  {
    program: "npm",
    args: ["config", "get", "registry", "--location=\{scope.to_text()}"],
  }
}

///|
fn pnpm_get_command(scope : Scope) -> Command {
  let location = match scope {
    Project => "project"
    User | System => "global"
  }
  {
    program: "pnpm",
    args: ["config", "get", "--location=\{location}", "registry"],
  }
}

///|
fn yarn_get_command() -> Command {
  { program: "yarn", args: ["config", "get", "npmRegistryServer"], }
}

///|
fn pip_get_command(scope : Scope) -> Command {
  let scope_flag = match scope {
    Project => "--site"
    User => "--user"
    System => "--global"
  }
  {
    program: "python",
    args: ["-m", "pip", "config", scope_flag, "get", "global.index-url"],
  }
}

///|
fn go_get_command() -> Command {
  { program: "go", args: ["env", "GOPROXY"], }
}

///|
fn composer_config_args(scope : Scope) -> Array[String] {
  let args = ["config"]
  if scope == User {
    args.push("--global")
  }
  args
}

///|
fn composer_command(source : Source, scope : Scope) -> Command {
  let args = composer_config_args(scope)
  args.push("repositories.packagist")
  args.push("composer")
  args.push(source.url)
  { program: "composer", args, }
}

///|
fn composer_get_command(scope : Scope) -> Command {
  let args = composer_config_args(scope)
  args.push("repositories.packagist.url")
  { program: "composer", args, }
}

///|
fn cargo_path(scope : Scope) -> ConfigPath {
  match scope {
    Project => CargoProject
    User | System => CargoUser
  }
}

///|
fn cargo_set_file_steps(source : Source, scope : Scope) -> Array[FileStep] {
  let operation = if source.mirror_id == "official" {
    ResetCargoSource
  } else {
    SetCargoSource("sparse+\{source.url}")
  }
  [{ path: cargo_path(scope), operation, }]
}

///|
fn cargo_get_file_steps(scope : Scope) -> Array[FileStep] {
  [{ path: cargo_path(scope), operation: ReadCargoSource, }]
}

///|
fn cargo_restore_file_steps(
  values : ArrayView[SavedValue],
  scope : Scope,
) -> Array[FileStep] {
  [{ path: cargo_path(scope), operation: RestoreContent(values[0]), }]
}

///|
fn moon_set_file_steps(source : Source, _scope : Scope) -> Array[FileStep] {
  let operation = if source.mirror_id == "official" {
    ResetMooncakesSource
  } else {
    SetMooncakesSource(
      registry=source.url,
      index="\{source.url}.git",
      symbols="\{source.url}/symbols.zip",
    )
  }
  [{ path: MoonUser, operation, }]
}

///|
fn moon_get_file_steps(_scope : Scope) -> Array[FileStep] {
  [{ path: MoonUser, operation: ReadMooncakesSource, }]
}

///|
fn moon_restore_file_steps(
  values : ArrayView[SavedValue],
  _scope : Scope,
) -> Array[FileStep] {
  [{ path: MoonUser, operation: RestoreContent(values[0]), }]
}

///|
fn require_saved_value(
  target : String,
  value : SavedValue,
) -> String? raise PlanError {
  match value {
    Present(source) => Some(source)
    Missing => None
    Redacted => raise SnapshotNotRestorable(target)
  }
}

///|
fn npm_restore_command(
  value : SavedValue,
  scope : Scope,
) -> Command raise PlanError {
  match require_saved_value("npm", value) {
    Some(url) => npm_command({ mirror_id: "history", url, }, scope)
    None =>
      {
        program: "npm",
        args: ["config", "delete", "registry", "--location=\{scope.to_text()}"],
      }
  }
}

///|
fn pnpm_restore_command(
  value : SavedValue,
  scope : Scope,
) -> Command raise PlanError {
  match require_saved_value("pnpm", value) {
    Some(url) => pnpm_command({ mirror_id: "history", url, }, scope)
    None => {
      let location = match scope {
        Project => "project"
        User | System => "global"
      }
      {
        program: "pnpm",
        args: ["config", "delete", "--location=\{location}", "registry"],
      }
    }
  }
}

///|
fn yarn_restore_command(
  value : SavedValue,
  scope : Scope,
) -> Command raise PlanError {
  match require_saved_value("yarn", value) {
    Some(url) => yarn_command({ mirror_id: "history", url, }, scope)
    None => {
      let args = ["config", "unset", "npmRegistryServer"]
      if scope == User {
        args.push("--home")
      }
      { program: "yarn", args, }
    }
  }
}

///|
fn pip_restore_command(
  value : SavedValue,
  scope : Scope,
) -> Command raise PlanError {
  match require_saved_value("pip", value) {
    Some(url) => pip_command({ mirror_id: "history", url, }, scope)
    None => {
      let scope_flag = match scope {
        Project => "--site"
        User => "--user"
        System => "--global"
      }
      {
        program: "python",
        args: ["-m", "pip", "config", scope_flag, "unset", "global.index-url"],
      }
    }
  }
}

///|
fn go_restore_command(value : SavedValue) -> Command raise PlanError {
  match require_saved_value("go", value) {
    Some(url) => go_command({ mirror_id: "history", url, })
    None => { program: "go", args: ["env", "-u", "GOPROXY"], }
  }
}

///|
fn composer_restore_command(
  value : SavedValue,
  scope : Scope,
) -> Command raise PlanError {
  match require_saved_value("composer", value) {
    Some(url) => composer_command({ mirror_id: "history", url, }, scope)
    None => {
      let args = composer_config_args(scope)
      args.push("--unset")
      args.push("repositories.packagist")
      { program: "composer", args, }
    }
  }
}

///|
fn rubygems_clear_command() -> Command {
  { program: "gem", args: ["sources", "--clear-all", "--force"], }
}

///|
fn rubygems_add_command(url : String) -> Command {
  { program: "gem", args: ["sources", "--add", url, "--force"], }
}

///|
fn rubygems_set_commands(source : Source) -> Array[Command] {
  [rubygems_clear_command(), rubygems_add_command(source.url)]
}

///|
fn rubygems_get_command() -> Command {
  { program: "gem", args: ["sources", "--list"], }
}

///|
fn rubygems_restore_commands(
  value : SavedValue,
) -> Array[Command] raise PlanError {
  let commands = [rubygems_clear_command()]
  match require_saved_value("rubygems", value) {
    Some(urls) =>
      for url in urls.split("\n") {
        let source = url.trim(chars=" \t\r")
        if source != "" {
          commands.push(rubygems_add_command(source.to_owned()))
        }
      }
    None => ()
  }
  commands
}

///|
fn require_snapshot_size(
  target : String,
  values : ArrayView[SavedValue],
  expected : Int,
) -> Unit raise PlanError {
  if values.length() != expected {
    raise InvalidSnapshot(target~, expected~, actual=values.length())
  }
}

///|
/// Resolve a target, mirror, and scope into an exact command plan.
pub fn plan_change(
  target_name : StringView,
  mirror_name : StringView,
  scope? : Scope = User,
) -> ChangePlan raise PlanError {
  let recipe = match find_recipe(target_name) {
    Some(recipe) => recipe
    None => raise UnknownTarget(target_name.to_owned())
  }
  let target = recipe.target
  if !target.scopes.contains(scope) {
    raise UnsupportedScope(target=target.id, scope~)
  }
  let mirror_id = mirror_name.to_owned().to_lower()
  let source = match target.find_source(mirror_id) {
    Some(source) => source
    None => raise UnknownMirror(target=target.id, mirror=mirror_id)
  }
  let commands = (recipe.set_commands)(source, scope)
  let file_steps = (recipe.set_file_steps)(source, scope)
  {
    operation: SetSource,
    target_id: target.id,
    mirror_id: Some(mirror_id),
    scope,
    commands,
    file_steps,
  }
}

///|
/// Reset a target to its official upstream source.
pub fn plan_reset(
  target_name : StringView,
  scope? : Scope = User,
) -> ChangePlan raise PlanError {
  let plan = plan_change(target_name, "official", scope~)
  { ..plan, operation: ResetSource, }
}

///|
/// Select the first maintainer-preferred mirror. Official upstream is kept as
/// the reset destination and is therefore skipped here.
pub fn plan_first(
  target_name : StringView,
  scope? : Scope = User,
) -> ChangePlan raise PlanError {
  let target = match find_target(target_name) {
    Some(target) => target
    None => raise UnknownTarget(target_name.to_owned())
  }
  let source = match
    target.sources.search_by(source => source.mirror_id != "official") {
    Some(index) => target.sources[index]
    None => raise NoSelectableMirror(target.id)
  }
  plan_change(target.id, source.mirror_id, scope~)
}

///|
/// Build a read-only plan that prints the currently effective source.
pub fn plan_get(
  target_name : StringView,
  scope? : Scope = User,
) -> ChangePlan raise PlanError {
  let recipe = match find_recipe(target_name) {
    Some(recipe) => recipe
    None => raise UnknownTarget(target_name.to_owned())
  }
  let target = recipe.target
  if !target.scopes.contains(scope) {
    raise UnsupportedScope(target=target.id, scope~)
  }
  let commands = (recipe.get_commands)(scope)
  let file_steps = (recipe.get_file_steps)(scope)
  {
    operation: GetSource,
    target_id: target.id,
    mirror_id: None,
    scope,
    commands,
    file_steps,
  }
}

///|
/// Convert a previously captured snapshot into exact restoration commands.
pub fn plan_restore(snapshot : Snapshot) -> ChangePlan raise PlanError {
  let recipe = match find_recipe(snapshot.target_id) {
    Some(recipe) => recipe
    None => raise UnknownTarget(snapshot.target_id)
  }
  if !snapshot.is_restorable() {
    raise SnapshotNotRestorable(snapshot.target_id)
  }
  let commands = (recipe.restore_commands)(snapshot.values, snapshot.scope)
  let file_steps = (recipe.restore_file_steps)(snapshot.values, snapshot.scope)
  {
    operation: RestoreSource,
    target_id: snapshot.target_id,
    mirror_id: None,
    scope: snapshot.scope,
    commands,
    file_steps,
  }
}
