///|
/// A previously observed source value. Redacted values are deliberately not
/// persisted, preventing credentials embedded in URLs from entering history.
pub(all) enum SavedValue {
  Present(String)
  Missing
  Redacted
} derive(Debug, Eq, ToJson, FromJson)

///|
/// A point-in-time snapshot captured before a source-changing operation.
pub(all) struct Snapshot {
  target_id : String
  scope : Scope
  values : Array[SavedValue]
  captured_at : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
fn contains_sensitive_url_data(value : String) -> Bool {
  let lower = value.to_lower()
  if lower.contains("token=") ||
    lower.contains("password=") ||
    lower.contains("auth=") {
    return true
  }
  match lower.split_once("://") {
    Some((_, authority_and_path)) =>
      match authority_and_path.split_once("@") {
        Some((userinfo, _)) => userinfo.contains(":")
        None => false
      }
    None => false
  }
}

///|
/// Convert command output into a safe value for local history.
pub fn capture_value(exit_code : Int, output : StringView) -> SavedValue {
  if exit_code != 0 {
    return Missing
  }
  let value = output.to_owned().trim().to_owned()
  if value == "" {
    Missing
  } else if contains_sensitive_url_data(value) {
    Redacted
  } else {
    Present(value)
  }
}

///|
/// Capture a complete configuration file. Unlike command output, an empty
/// existing file must remain distinguishable from a file that did not exist.
pub fn capture_config_file(content : String) -> SavedValue {
  if contains_sensitive_url_data(content) ||
    content.to_lower().contains("token =") ||
    content.to_lower().contains("password =") ||
    content.to_lower().contains("auth =") {
    Redacted
  } else {
    Present(content)
  }
}

///|
/// Normalize the human-oriented output of `gem sources --list` into one URL
/// per line so it can be restored deterministically.
fn capture_rubygems_sources(exit_code : Int, output : StringView) -> SavedValue {
  if exit_code != 0 {
    return Missing
  }
  let urls : Array[String] = []
  for line in output.to_owned().split("\n") {
    let value = line.trim(chars=" \t\r")
    if value.has_prefix("https://") || value.has_prefix("http://") {
      urls.push(value.to_owned())
    }
  }
  capture_value(0, urls.iter().join("\n"))
}

///|
/// Extract the Flathub URL from Flatpak's machine-oriented name/url table.
fn capture_flathub_url(exit_code : Int, output : StringView) -> SavedValue {
  if exit_code != 0 {
    return Missing
  }
  for raw_line in output.to_owned().split("\n") {
    let line = raw_line.trim(chars=" \t\r").to_owned()
    if line.has_prefix("flathub\t") || line.has_prefix("flathub ") {
      let start = match line.find("https://") {
        Some(index) => Some(index)
        None => line.find("http://")
      }
      match start {
        Some(index) => return capture_value(0, line[index:])
        None => ()
      }
    }
  }
  Missing
}

///|
pub fn Snapshot::is_restorable(self : Snapshot) -> Bool {
  self.values.all(value => value != Redacted)
}
