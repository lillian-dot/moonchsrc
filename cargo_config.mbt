///|
let cargo_block_begin = "# BEGIN moonchsrc managed cargo source"

///|
let cargo_block_end = "# END moonchsrc managed cargo source"

///|
fn strip_cargo_block(content : String) -> String raise PlanError {
  let kept : Array[String] = []
  let mut inside = false
  let mut found = false
  for line in content.split("\n") {
    let owned = line.to_owned()
    let trimmed = line.trim(chars=" \t\r")
    if trimmed == cargo_block_begin {
      if inside || found {
        raise ConfigConflict(
          path="Cargo config.toml",
          detail="duplicate or nested MoonChsrc managed block",
        )
      }
      inside = true
      found = true
    } else if trimmed == cargo_block_end {
      if !inside {
        raise ConfigConflict(
          path="Cargo config.toml",
          detail="managed block end marker has no matching begin marker",
        )
      }
      inside = false
    } else if !inside {
      kept.push(owned)
    }
  }
  if inside {
    raise ConfigConflict(
      path="Cargo config.toml",
      detail="managed block begin marker has no matching end marker",
    )
  }
  kept.iter().join("\n")
}

///|
fn has_unmanaged_cargo_source(content : String) -> Bool {
  content
  .split("\n")
  .any(line => {
    let trimmed = line.trim(chars=" \t\r")
    trimmed == "[source.crates-io]" || trimmed == "[source.moonchsrc]"
  })
}

///|
/// Add or replace MoonChsrc's isolated Cargo source block. Existing Cargo
/// source tables outside the managed block are rejected instead of overwritten.
pub fn set_cargo_mirror_config(
  content : String,
  registry_url : String,
) -> String raise PlanError {
  if registry_url.contains("\"") ||
    registry_url.contains("\n") ||
    registry_url.contains("\r") {
    raise UnsafeConfigValue(registry_url)
  }
  let base = strip_cargo_block(content)
  if has_unmanaged_cargo_source(base) {
    raise ConfigConflict(
      path="Cargo config.toml",
      detail="existing source.crates-io or source.moonchsrc table is not managed by MoonChsrc",
    )
  }
  let separator = if base == "" || base.has_suffix("\n") { "" } else { "\n" }
  base +
  separator +
  (
    #|# BEGIN moonchsrc managed cargo source
    #|[source.crates-io]
    #|replace-with = "moonchsrc"
    #|
    #|[source.moonchsrc]
    #|registry = "
  ) +
  registry_url +
  (
    #|"
    #|# END moonchsrc managed cargo source
    #|
  )
}

///|
/// Remove only the block owned by MoonChsrc.
pub fn reset_cargo_mirror_config(content : String) -> String raise PlanError {
  strip_cargo_block(content)
}

///|
/// Read the registry URL from MoonChsrc's managed block. Unmanaged Cargo
/// configuration is intentionally not interpreted as one of our mirrors.
pub fn get_cargo_mirror_config(content : String) -> String? raise PlanError {
  let mut inside = false
  let mut found = false
  let mut registry = None
  for line in content.split("\n") {
    let trimmed = line.trim(chars=" \t\r")
    if trimmed == cargo_block_begin {
      if inside || found {
        raise ConfigConflict(
          path="Cargo config.toml",
          detail="duplicate or nested MoonChsrc managed block",
        )
      }
      inside = true
      found = true
    } else if trimmed == cargo_block_end {
      if !inside {
        raise ConfigConflict(
          path="Cargo config.toml",
          detail="managed block end marker has no matching begin marker",
        )
      }
      inside = false
    } else if inside {
      match trimmed.strip_prefix("registry = \"") {
        Some(rest) =>
          match rest.strip_suffix("\"") {
            Some(url) => registry = Some(url.to_owned())
            None => ()
          }
        None => ()
      }
    }
  }
  if inside {
    raise ConfigConflict(
      path="Cargo config.toml",
      detail="managed block begin marker has no matching end marker",
    )
  }
  registry
}
