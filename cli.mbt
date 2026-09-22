///|
pub fn help_text() -> String {
  (
    #|MoonChsrc - source switching for developer tools
    #|
    #|Usage:
    #|  moonchsrc list
    #|  moonchsrc list mirror|target|<target>
    #|  moonchsrc plan <target> <mirror> [project|user|system]
    #|  moonchsrc set [--dry-run] <target> [auto|first|<mirror>] [project|user|system]
    #|  moonchsrc get [--dry-run] <target> [project|user|system]
    #|  moonchsrc reset [--dry-run] <target> [project|user|system]
    #|  moonchsrc restore [--dry-run] <target> [project|user|system]
    #|  moonchsrc measure <target>
    #|
    #|Use --dry-run to preview the exact command without changing configuration.
    #|
  )
}

///|
pub fn render_error(error : PlanError) -> String {
  match error {
    UnknownTarget(target) => "error: unknown target '\{target}'"
    UnknownMirror(target~, mirror~) =>
      "error: target '\{target}' does not support mirror '\{mirror}'"
    InvalidScope(scope) => "error: invalid scope '\{scope}'"
    UnsupportedScope(target~, scope~) =>
      "error: target '\{target}' does not support scope '\{scope.to_text()}'"
    InvalidSnapshot(target~, expected~, actual~) =>
      "error: snapshot for '\{target}' contains \{actual} values; expected \{expected}"
    SnapshotNotRestorable(target) =>
      "error: snapshot for '\{target}' contains redacted credentials and cannot be restored"
    NoSelectableMirror(target) =>
      "error: target '\{target}' has no selectable mirror"
    ConfigConflict(path~, detail~) =>
      "error: refusing to edit \{path}: \{detail}"
    UnsafeConfigValue(value) =>
      "error: unsafe value cannot be written to configuration: '\{value}'"
  }
}

///|
fn render_plan(
  target : String,
  mirror : String,
  scope_text? : String = "user",
) -> String {
  let scope = match Scope::parse(scope_text) {
    Some(scope) => scope
    None => return render_error(InvalidScope(scope_text))
  }
  try plan_change(target, mirror, scope~) catch {
    error => render_error(error)
  } noraise {
    plan => "Dry-run plan (no changes made):\n\{plan.to_text()}"
  }
}

///|
fn apply_plan(
  target : String,
  mirror : String,
  scope_text? : String = "user",
) -> CliAction {
  let scope = match Scope::parse(scope_text) {
    Some(scope) => scope
    None => return Show(render_error(InvalidScope(scope_text)))
  }
  try plan_change(target, mirror, scope~) catch {
    error => Show(render_error(error))
  } noraise {
    plan => Execute(plan)
  }
}

///|
fn render_first(target : String, scope_text? : String = "user") -> String {
  let scope = match Scope::parse(scope_text) {
    Some(scope) => scope
    None => return render_error(InvalidScope(scope_text))
  }
  try plan_first(target, scope~) catch {
    error => render_error(error)
  } noraise {
    plan => "Dry-run plan (no changes made):\n\{plan.to_text()}"
  }
}

///|
fn apply_first(target : String, scope_text? : String = "user") -> CliAction {
  let scope = match Scope::parse(scope_text) {
    Some(scope) => scope
    None => return Show(render_error(InvalidScope(scope_text)))
  }
  try plan_first(target, scope~) catch {
    error => Show(render_error(error))
  } noraise {
    plan => Execute(plan)
  }
}

///|
fn auto_select_action(
  target : String,
  scope_text? : String = "user",
  dry_run? : Bool = false,
) -> CliAction {
  let scope = match Scope::parse(scope_text) {
    Some(scope) => scope
    None => return Show(render_error(InvalidScope(scope_text)))
  }
  match find_target(target) {
    Some(found) if found.scopes.contains(scope) =>
      AutoSelect(found.id, scope, dry_run)
    Some(found) => Show(render_error(UnsupportedScope(target=found.id, scope~)))
    None => Show(render_error(UnknownTarget(target)))
  }
}

///|
fn render_reset(target : String, scope_text? : String = "user") -> String {
  let scope = match Scope::parse(scope_text) {
    Some(scope) => scope
    None => return render_error(InvalidScope(scope_text))
  }
  try plan_reset(target, scope~) catch {
    error => render_error(error)
  } noraise {
    plan => "Dry-run plan (no changes made):\n\{plan.to_text()}"
  }
}

///|
fn apply_reset(target : String, scope_text? : String = "user") -> CliAction {
  let scope = match Scope::parse(scope_text) {
    Some(scope) => scope
    None => return Show(render_error(InvalidScope(scope_text)))
  }
  try plan_reset(target, scope~) catch {
    error => Show(render_error(error))
  } noraise {
    plan => Execute(plan)
  }
}

///|
fn render_get(target : String, scope_text? : String = "user") -> String {
  let scope = match Scope::parse(scope_text) {
    Some(scope) => scope
    None => return render_error(InvalidScope(scope_text))
  }
  try plan_get(target, scope~) catch {
    error => render_error(error)
  } noraise {
    plan => "Read-only plan:\n\{plan.to_text()}"
  }
}

///|
fn execute_get(target : String, scope_text? : String = "user") -> CliAction {
  let scope = match Scope::parse(scope_text) {
    Some(scope) => scope
    None => return Show(render_error(InvalidScope(scope_text)))
  }
  try plan_get(target, scope~) catch {
    error => Show(render_error(error))
  } noraise {
    plan => Execute(plan)
  }
}

///|
fn restore_latest_action(
  target : String,
  scope_text? : String = "user",
  dry_run? : Bool = false,
) -> CliAction {
  match Scope::parse(scope_text) {
    Some(scope) => RestoreLatest(target, scope, dry_run)
    None => Show(render_error(InvalidScope(scope_text)))
  }
}

///|
/// Parse CLI arguments into either display output or an execution plan.
pub fn dispatch_cli(args : ArrayView[String]) -> CliAction {
  match args {
    [] | ["help"] | ["-h"] | ["--help"] => Show(help_text())
    ["version"] | ["-V"] | ["--version"] => Show(version())
    ["list"] | ["ls"] | ["l"] => Show(render_targets())
    ["list", "mirror"] | ["list", "mirrors"] => Show(render_mirrors())
    ["list", "target"] | ["list", "targets"] => Show(render_targets())
    ["list", target] =>
      try render_target(target) catch {
        error => Show(render_error(error))
      } noraise {
        output => Show(output)
      }
    ["plan", target, mirror] => Show(render_plan(target, mirror))
    ["plan", target, mirror, scope] =>
      Show(render_plan(target, mirror, scope_text=scope))
    ["set", "--dry-run", target] => auto_select_action(target, dry_run=true)
    ["set", "--dry-run", target, "auto"] =>
      auto_select_action(target, dry_run=true)
    ["set", "--dry-run", target, "auto", scope] =>
      auto_select_action(target, scope_text=scope, dry_run=true)
    ["set", "--dry-run", target, "first"] => Show(render_first(target))
    ["set", "--dry-run", target, "first", scope] =>
      Show(render_first(target, scope_text=scope))
    ["set", "--dry-run", target, mirror] => Show(render_plan(target, mirror))
    ["set", "--dry-run", target, mirror, scope] =>
      Show(render_plan(target, mirror, scope_text=scope))
    ["set", target] => auto_select_action(target)
    ["set", target, "auto"] => auto_select_action(target)
    ["set", target, "auto", scope] =>
      auto_select_action(target, scope_text=scope)
    ["set", target, "first"] => apply_first(target)
    ["set", target, "first", scope] => apply_first(target, scope_text=scope)
    ["set", target, mirror] => apply_plan(target, mirror)
    ["set", target, mirror, scope] =>
      apply_plan(target, mirror, scope_text=scope)
    ["get", "--dry-run", target] => Show(render_get(target))
    ["get", "--dry-run", target, scope] =>
      Show(render_get(target, scope_text=scope))
    ["get", target] => execute_get(target)
    ["get", target, scope] => execute_get(target, scope_text=scope)
    ["reset", "--dry-run", target] => Show(render_reset(target))
    ["reset", "--dry-run", target, scope] =>
      Show(render_reset(target, scope_text=scope))
    ["reset", target] => apply_reset(target)
    ["reset", target, scope] => apply_reset(target, scope_text=scope)
    ["restore", "--dry-run", target] =>
      restore_latest_action(target, dry_run=true)
    ["restore", "--dry-run", target, scope] =>
      restore_latest_action(target, scope_text=scope, dry_run=true)
    ["restore", target] => restore_latest_action(target)
    ["restore", target, scope] =>
      restore_latest_action(target, scope_text=scope)
    ["measure", target] =>
      match find_target(target) {
        Some(found) => MeasureTarget(found.id)
        None => Show(render_error(UnknownTarget(target)))
      }
    _ => Show("error: invalid arguments\n\n\{help_text()}")
  }
}

///|
/// Run the pure display form of the CLI. Execution requests are rendered but
/// never launched; the native executable handles Execute explicitly.
pub fn run_cli(args : ArrayView[String]) -> String {
  match dispatch_cli(args) {
    Show(output) => output
    Execute(plan) => "Execution requested:\n\{plan.to_text()}"
    RestoreLatest(target, scope, dry_run) =>
      "Restore requested for \{target} at \{scope.to_text()} scope (dry-run: \{dry_run})"
    MeasureTarget(target) => "Measurement requested for \{target}"
    AutoSelect(target, scope, dry_run) =>
      "Automatic selection requested for \{target} at \{scope.to_text()} scope (dry-run: \{dry_run})"
  }
}
