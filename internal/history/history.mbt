///|
/// Persist snapshots as deterministic, human-inspectable JSON.
pub async fn save(
  path : StringView,
  snapshots : ArrayView[@moonchsrc.Snapshot],
) -> Unit {
  let content = @json.to_json(snapshots).stringify(indent=2)
  @fs.write_file(path, content)
  // History can contain private registry URLs even after credentials are
  // redacted. Windows uses inherited ACLs and does not support POSIX chmod.
  if !is_windows() {
    @fs.chmod(path, 0o600)
  }
}

///|
/// Load snapshot history. A missing file represents an empty history.
pub async fn load(path : StringView) -> Array[@moonchsrc.Snapshot] {
  if !@fs.exists(path) {
    return []
  }
  let content = @fs.read_file(path).text()
  @json.from_json(@json.parse(content))
}

///|
/// Choose the state directory without consulting process-global state.
///
/// Keeping this rule pure makes the Windows and Unix paths testable on every
/// CI runner. `LOCALAPPDATA` takes precedence because it is the native Windows
/// location; Unix follows the XDG state directory convention and then HOME.
pub fn select_state_directory(
  local_app_data : String?,
  xdg_state_home : String?,
  home : String?,
) -> String {
  match local_app_data {
    Some(root) => "\{root}/moonchsrc"
    None =>
      match xdg_state_home {
        Some(root) => "\{root}/moonchsrc"
        None =>
          match home {
            Some(root) => "\{root}/.local/state/moonchsrc"
            None => ".moonchsrc"
          }
      }
  }
}

///|
fn state_directory() -> String {
  select_state_directory(
    @env.get_env_var("LOCALAPPDATA"),
    @env.get_env_var("XDG_STATE_HOME"),
    @env.get_env_var("HOME"),
  )
}

///|
fn is_windows() -> Bool {
  match @env.get_env_var("OS") {
    Some(name) => name == "Windows_NT"
    None => false
  }
}

///|
pub fn default_path() -> String {
  "\{state_directory()}/history.json"
}

///|
/// Append one snapshot to the default local history file.
pub async fn append_default(snapshot : @moonchsrc.Snapshot) -> String {
  let directory = state_directory()
  if !@fs.exists(directory) {
    @fs.mkdir(directory, recursive=true)
  }
  if !is_windows() {
    @fs.chmod(directory, 0o700)
  }
  let path = default_path()
  let snapshots = load(path)
  snapshots.push(snapshot)
  save(path, snapshots)
  path
}

///|
/// Return the newest snapshot matching a target and scope.
pub fn latest_matching(
  snapshots : ArrayView[@moonchsrc.Snapshot],
  target : StringView,
  scope : @moonchsrc.Scope,
) -> @moonchsrc.Snapshot? {
  let length = snapshots.length()
  for offset in 0..<length {
    let snapshot = snapshots[length - offset - 1]
    if target.equal_to_string(snapshot.target_id) && snapshot.scope == scope {
      return Some(snapshot)
    }
  }
  None
}

///|
pub async fn latest_default(
  target : StringView,
  scope : @moonchsrc.Scope,
) -> @moonchsrc.Snapshot? {
  latest_matching(load(default_path()), target, scope)
}
