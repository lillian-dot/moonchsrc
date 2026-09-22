///|
async fn execute_plan(plan : @moonchsrc.ChangePlan) -> Unit {
  match plan.operation {
    GetSource => println("Current source for \{plan.target_id}:")
    RestoreSource => println("Restoring previous \{plan.target_id} source...")
    SetSource | ResetSource =>
      match plan.mirror_id {
        Some(mirror) =>
          println("Applying \{plan.target_id} source '\{mirror}'...")
        None => ()
      }
  }
  let exit_code = @executor.execute(plan)
  if exit_code == 0 {
    if plan.operation != GetSource {
      println("Done.")
    }
  } else {
    println("Command failed with exit code \{exit_code}.")
    @sys.exit(exit_code)
  }
}

///|
async fn restore_latest(
  target : String,
  scope : @moonchsrc.Scope,
  dry_run : Bool,
) -> Unit {
  match @history.latest_default(target, scope) {
    None => {
      println(
        "error: no saved snapshot for '\{target}' at \{scope.to_text()} scope",
      )
      @sys.exit(1)
    }
    Some(snapshot) =>
      try @moonchsrc.plan_restore(snapshot) catch {
        error => {
          println(@moonchsrc.render_error(error))
          @sys.exit(1)
        }
      } noraise {
        plan =>
          if dry_run {
            println(
              "Dry-run restore plan (no changes made):\n\{plan.to_text()}",
            )
          } else {
            execute_plan(plan)
          }
      }
  }
}

///|
async fn measure_target(target : String) -> Unit {
  println("Measuring mirrors for \{target}...")
  let measurements = @measure.target(target)
  println(@moonchsrc.render_measurements(measurements))
}

///|
async fn auto_select(
  target : String,
  scope : @moonchsrc.Scope,
  dry_run : Bool,
) -> Unit {
  println("Measuring mirrors for \{target}...")
  let measurements = @measure.target(target)
  println(@moonchsrc.render_measurements(measurements))
  match @moonchsrc.fastest_reachable(measurements) {
    None => {
      println("error: no reachable source for '\{target}'")
      @sys.exit(1)
    }
    Some(fastest) =>
      try @moonchsrc.plan_change(target, fastest.mirror_id, scope~) catch {
        error => {
          println(@moonchsrc.render_error(error))
          @sys.exit(1)
        }
      } noraise {
        plan => {
          let latency = match fastest.latency_ms {
            Some(value) => value
            None => 0L
          }
          println("Selected '\{fastest.mirror_id}' (\{latency} ms).")
          if dry_run {
            println("Dry-run plan (no changes made):\n\{plan.to_text()}")
          } else {
            execute_plan(plan)
          }
        }
      }
  }
}

///|
async fn main {
  let action = match @env.args() {
    [_, .. args] => @moonchsrc.dispatch_cli(args)
    [] => Show(@moonchsrc.help_text())
  }
  match action {
    Show(output) => println(output)
    Execute(plan) => execute_plan(plan)
    RestoreLatest(target, scope, dry_run) =>
      restore_latest(target, scope, dry_run)
    MeasureTarget(target) => measure_target(target)
    AutoSelect(target, scope, dry_run) => auto_select(target, scope, dry_run)
  }
}
