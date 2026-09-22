///|
async test "snapshot history round trip" {
  let dir = @fs.tmpdir(prefix="moonchsrc-history-")
  let path = "\{dir}/history.json"
  let snapshots = [
    @moonchsrc.Snapshot::{
      target_id: "npm",
      scope: User,
      values: [Present("https://registry.npmjs.org/")],
      captured_at: 42,
    },
  ]
  @history.save(path, snapshots)
  let loaded = @history.load(path)
  assert_eq(loaded, snapshots)
  @fs.rmdir(dir, recursive=true)
}

///|
test "latest matching snapshot wins" {
  let older = @moonchsrc.Snapshot::{
    target_id: "npm",
    scope: User,
    values: [Present("https://old.example/")],
    captured_at: 1,
  }
  let newer = {
    ..older,
    values: [Present("https://new.example/")],
    captured_at: 2,
  }
  let unrelated = { ..newer, target_id: "pip", }
  assert_eq(
    @history.latest_matching([older, newer, unrelated], "npm", User),
    Some(newer),
  )
}

///|
test "state directory follows platform precedence" {
  assert_eq(
    @history.select_state_directory(
      Some("C:/Users/test/AppData/Local"),
      Some("/tmp/xdg"),
      Some("/home/test"),
    ),
    "C:/Users/test/AppData/Local/moonchsrc",
  )
  assert_eq(
    @history.select_state_directory(None, Some("/tmp/xdg"), Some("/home/test")),
    "/tmp/xdg/moonchsrc",
  )
  assert_eq(
    @history.select_state_directory(None, None, Some("/home/test")),
    "/home/test/.local/state/moonchsrc",
  )
  assert_eq(@history.select_state_directory(None, None, None), ".moonchsrc")
}
