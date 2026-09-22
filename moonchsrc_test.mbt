///|
test "target aliases resolve" {
  guard @moonchsrc.find_target("pypi") is Some(target) else {
    fail("expected pypi alias to resolve")
  }
  assert_eq(target.id, "pip")
}

///|
test "npm plan uses requested user scope" {
  let plan = @moonchsrc.plan_change("npm", "npmmirror")
  assert_eq(plan.target_id, "npm")
  assert_eq(plan.mirror_id, Some("npmmirror"))
  assert_eq(plan.scope, User)
  assert_eq(
    plan.commands[0].to_text(),
    "npm config set registry https://registry.npmmirror.com/ --location=user",
  )
}

///|
test "pip plan uses project-local configuration" {
  let plan = @moonchsrc.plan_change("python", "tuna", scope=Project)
  assert_eq(
    plan.commands[0].to_text(),
    "python -m pip config --site set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple",
  )
}

///|
test "unknown mirror is a typed error" {
  try @moonchsrc.plan_change("npm", "tuna") catch {
    UnknownMirror(target~, mirror~) => {
      assert_eq(target, "npm")
      assert_eq(mirror, "tuna")
    }
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected plan creation to fail")
  }
}

///|
test "CLI only previews source changes" {
  let output = @moonchsrc.run_cli([
    "set", "--dry-run", "npm", "official", "project",
  ])
  assert_true(output.has_prefix("Dry-run plan (no changes made):"))
  assert_true(output.contains("--location=project"))
}

///|
test "CLI separates execution from parsing" {
  guard @moonchsrc.dispatch_cli(["set", "pip", "ustc", "user"]) is Execute(plan) else {
    fail("expected an execution plan")
  }
  assert_eq(plan.target_id, "pip")
  assert_eq(plan.mirror_id, Some("ustc"))
  assert_eq(plan.operation, SetSource)
}

///|
test "reset selects official upstream" {
  let plan = @moonchsrc.plan_reset("npm", scope=Project)
  assert_eq(plan.operation, ResetSource)
  assert_eq(plan.mirror_id, Some("official"))
  assert_true(
    plan.commands[0].to_text().contains("https://registry.npmjs.org/"),
  )
}

///|
test "node recipe configures three package managers" {
  let plan = @moonchsrc.plan_change("nodejs", "npmmirror", scope=User)
  assert_eq(plan.commands.length(), 3)
  assert_true(plan.commands[0].to_text().has_prefix("npm config set"))
  assert_true(plan.commands[1].to_text().has_prefix("pnpm config set"))
  assert_true(plan.commands[2].to_text().has_prefix("yarn config set"))
  assert_true(plan.commands[2].to_text().contains("--home"))
}

///|
test "Go recipe only permits persistent user scope" {
  let plan = @moonchsrc.plan_change("golang", "goproxycn")
  assert_eq(
    plan.commands[0].to_text(),
    "go env -w GOPROXY=https://goproxy.cn,direct",
  )
  try @moonchsrc.plan_change("go", "official", scope=Project) catch {
    UnsupportedScope(target~, scope~) => {
      assert_eq(target, "go")
      assert_eq(scope, Project)
    }
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected project scope to be rejected")
  }
}

///|
test "Composer recipe supports project and user configuration" {
  let set_plan = @moonchsrc.plan_change("packagist", "aliyun", scope=User)
  assert_eq(
    set_plan.commands[0].to_text(),
    "composer config --global repositories.packagist composer https://mirrors.aliyun.com/composer/",
  )
  let get_plan = @moonchsrc.plan_get("composer", scope=Project)
  assert_eq(
    get_plan.commands[0].to_text(),
    "composer config repositories.packagist.url",
  )
  let snapshot = @moonchsrc.Snapshot::{
    target_id: "composer",
    scope: User,
    values: [Missing],
    captured_at: 3,
  }
  assert_eq(
    @moonchsrc.plan_restore(snapshot).commands[0].to_text(),
    "composer config --global --unset repositories.packagist",
  )
}

///|
test "get plans are read-only and mirror agnostic" {
  let plan = @moonchsrc.plan_get("node", scope=Project)
  assert_eq(plan.operation, GetSource)
  assert_eq(plan.mirror_id, None)
  assert_eq(plan.commands.length(), 3)
  assert_true(plan.commands[0].to_text().contains("config get registry"))
  assert_true(
    plan.commands[2].to_text().contains("config get npmRegistryServer"),
  )
}

///|
test "history capture redacts credentials" {
  assert_eq(
    @moonchsrc.capture_value(0, "https://user:secret@example.com/simple\n"),
    Redacted,
  )
  assert_eq(
    @moonchsrc.capture_value(0, "https://example.com/simple\n"),
    Present("https://example.com/simple"),
  )
  assert_eq(@moonchsrc.capture_value(1, ""), Missing)
}

///|
test "redacted snapshots cannot be restored" {
  let safe = @moonchsrc.Snapshot::{
    target_id: "npm",
    scope: User,
    values: [Present("https://registry.npmjs.org/")],
    captured_at: 1,
  }
  let redacted = { ..safe, values: [Redacted], }
  assert_true(safe.is_restorable())
  assert_false(redacted.is_restorable())
}

///|
test "restore plans preserve present and missing values" {
  let npm_snapshot = @moonchsrc.Snapshot::{
    target_id: "npm",
    scope: User,
    values: [Present("https://private.example/")],
    captured_at: 1,
  }
  let npm_plan = @moonchsrc.plan_restore(npm_snapshot)
  assert_eq(npm_plan.operation, RestoreSource)
  assert_true(
    npm_plan.commands[0].to_text().contains("https://private.example/"),
  )
  let pip_snapshot = @moonchsrc.Snapshot::{
    target_id: "pip",
    scope: Project,
    values: [Missing],
    captured_at: 2,
  }
  let pip_plan = @moonchsrc.plan_restore(pip_snapshot)
  assert_eq(
    pip_plan.commands[0].to_text(),
    "python -m pip config --site unset global.index-url",
  )
}

///|
test "restore rejects malformed snapshots" {
  let snapshot = @moonchsrc.Snapshot::{
    target_id: "node",
    scope: User,
    values: [Present("https://registry.npmjs.org/")],
    captured_at: 1,
  }
  try @moonchsrc.plan_restore(snapshot) catch {
    InvalidSnapshot(target~, expected~, actual~) => {
      assert_eq(target, "node")
      assert_eq(expected, 3)
      assert_eq(actual, 1)
    }
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected malformed snapshot to fail")
  }
}

///|
test "restore CLI action keeps dry-run intent" {
  assert_eq(
    @moonchsrc.dispatch_cli(["restore", "--dry-run", "npm", "project"]),
    RestoreLatest("npm", Project, true),
  )
}

///|
test "measurement ranking is stable and keeps failures last" {
  let ranked = @moonchsrc.rank_measurements([
    {
      mirror_id: "official",
      url: "https://official.example",
      latency_ms: Some(20L),
      http_status: Some(200),
    },
    {
      mirror_id: "first-tie",
      url: "https://first.example",
      latency_ms: Some(10L),
      http_status: Some(200),
    },
    {
      mirror_id: "failed",
      url: "https://failed.example",
      latency_ms: None,
      http_status: None,
    },
    {
      mirror_id: "second-tie",
      url: "https://second.example",
      latency_ms: Some(10L),
      http_status: Some(204),
    },
  ])
  assert_eq(ranked.map(result => result.mirror_id), [
    "first-tie", "second-tie", "official", "failed",
  ])
  assert_true(ranked[0].is_reachable())
  assert_false(ranked[3].is_reachable())
}

///|
test "measure CLI resolves aliases without doing network IO" {
  assert_eq(
    @moonchsrc.dispatch_cli(["measure", "nodejs"]),
    MeasureTarget("node"),
  )
}

///|
test "first selects the preferred non-official mirror" {
  let plan = @moonchsrc.plan_first("pip", scope=Project)
  assert_eq(plan.mirror_id, Some("tuna"))
  assert_true(plan.commands[0].to_text().contains("pypi.tuna.tsinghua.edu.cn"))
}

///|
test "automatic selection CLI remains separate from network IO" {
  assert_eq(
    @moonchsrc.dispatch_cli(["set", "--dry-run", "nodejs", "auto", "project"]),
    AutoSelect("node", Project, true),
  )
  assert_eq(
    @moonchsrc.dispatch_cli(["set", "npm"]),
    AutoSelect("npm", User, false),
  )
}

///|
test "Cargo managed block preserves unrelated configuration" {
  let original = "[net]\ngit-fetch-with-cli = true\n"
  let changed = @moonchsrc.set_cargo_mirror_config(
    original, "sparse+https://rsproxy.cn/index/",
  )
  assert_true(changed.has_prefix(original))
  assert_true(changed.contains("replace-with = \"moonchsrc\""))
  assert_true(
    changed.contains("registry = \"sparse+https://rsproxy.cn/index/\""),
  )
  assert_eq(@moonchsrc.reset_cargo_mirror_config(changed), original)
}

///|
test "Cargo editor refuses unmanaged source tables" {
  try
    @moonchsrc.set_cargo_mirror_config(
      "[source.crates-io]\nreplace-with = \"private\"\n", "sparse+https://rsproxy.cn/index/",
    )
  catch {
    ConfigConflict(path~, detail~) => {
      assert_eq(path, "Cargo config.toml")
      assert_true(detail.contains("not managed"))
    }
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected existing Cargo source configuration to be rejected")
  }
}

///|
test "Cargo editor replaces its own block idempotently" {
  let first = @moonchsrc.set_cargo_mirror_config(
    "", "sparse+https://rsproxy.cn/index/",
  )
  let second = @moonchsrc.set_cargo_mirror_config(
    first, "sparse+https://mirrors.ustc.edu.cn/crates.io-index/",
  )
  assert_false(second.contains("rsproxy.cn"))
  assert_true(second.contains("mirrors.ustc.edu.cn"))
  assert_eq(second.split("BEGIN moonchsrc").to_array().length(), 2)
}

///|
test "Cargo recipe plans typed file operations" {
  let set_plan = @moonchsrc.plan_change("rust", "rsproxy", scope=User)
  assert_eq(set_plan.commands.length(), 0)
  assert_eq(set_plan.file_steps, [
    {
      path: CargoUser,
      operation: SetCargoSource("sparse+https://rsproxy.cn/index/"),
    },
  ])
  let reset_plan = @moonchsrc.plan_reset("cargo", scope=Project)
  assert_eq(reset_plan.file_steps, [
    { path: CargoProject, operation: ResetCargoSource, },
  ])
  let restore_plan = @moonchsrc.plan_restore({
    target_id: "cargo",
    scope: User,
    values: [Missing],
    captured_at: 4,
  })
  assert_eq(restore_plan.file_steps, [
    { path: CargoUser, operation: RestoreContent(Missing), },
  ])
}

///|
test "configuration file capture preserves empty files and redacts tokens" {
  assert_eq(@moonchsrc.capture_config_file(""), Present(""))
  assert_eq(
    @moonchsrc.capture_config_file("[registry]\ntoken = \"secret\"\n"),
    Redacted,
  )
}

///|
test "MoonBit config editor preserves unrelated fields" {
  let original = "{\"telemetry\":false}"
  let changed = @moonchsrc.set_mooncakes_mirror_config(
    original, "https://mirrors.ustc.edu.cn/mooncakes", "https://mirrors.ustc.edu.cn/mooncakes.git",
    "https://mirrors.ustc.edu.cn/mooncakes/symbols.zip",
  )
  assert_true(changed.contains("\"telemetry\": false"))
  assert_eq(
    @moonchsrc.get_mooncakes_mirror_config(changed),
    Some("https://mirrors.ustc.edu.cn/mooncakes"),
  )
  let reset = @moonchsrc.reset_mooncakes_mirror_config(changed)
  assert_true(reset.contains("\"telemetry\": false"))
  assert_false(reset.contains("\"registry\""))
  assert_false(reset.contains("\"symbols\""))
}

///|
test "MoonBit recipe writes all registry endpoints" {
  let plan = @moonchsrc.plan_change("moonbit", "ustc")
  assert_eq(plan.commands.length(), 0)
  assert_eq(plan.file_steps, [
    {
      path: MoonUser,
      operation: SetMooncakesSource(
        registry="https://mirrors.ustc.edu.cn/mooncakes",
        index="https://mirrors.ustc.edu.cn/mooncakes.git",
        symbols="https://mirrors.ustc.edu.cn/mooncakes/symbols.zip",
      ),
    },
  ])
}

///|
test "RubyGems source output is normalized for restoration" {
  let captured = @moonchsrc.capture_command_value(
    "ruby", 0, "*** CURRENT SOURCES ***\n\nhttps://rubygems.org/\nhttps://private.example/\n",
  )
  assert_eq(
    captured,
    Present("https://rubygems.org/\nhttps://private.example/"),
  )
  let plan = @moonchsrc.plan_restore({
    target_id: "rubygems",
    scope: User,
    values: [captured],
    captured_at: 5,
  })
  assert_eq(plan.commands.length(), 3)
  assert_eq(plan.commands[0].to_text(), "gem sources --clear-all --force")
  assert_true(plan.commands[2].to_text().contains("private.example"))
}

///|
test "RubyGems set replaces the complete source list" {
  let plan = @moonchsrc.plan_change("gem", "rubychina")
  assert_eq(plan.commands.length(), 2)
  assert_eq(plan.commands[0].to_text(), "gem sources --clear-all --force")
  assert_eq(
    plan.commands[1].to_text(),
    "gem sources --add https://gems.ruby-china.com/ --force",
  )
}
