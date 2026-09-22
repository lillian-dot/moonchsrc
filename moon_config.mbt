///|
fn moon_config_object(content : String) -> Map[String, Json] raise PlanError {
  if content.trim() == "" {
    return Map([])
  }
  let parsed = try @json.parse(content) catch {
    _ =>
      raise ConfigConflict(
        path="MoonBit config.json",
        detail="file is not valid JSON",
      )
  } noraise {
    value => value
  }
  match parsed {
    Object(fields) => fields
    _ =>
      raise ConfigConflict(
        path="MoonBit config.json",
        detail="top-level JSON value must be an object",
      )
  }
}

///|
pub fn set_mooncakes_mirror_config(
  content : String,
  registry : String,
  index : String,
  symbols : String,
) -> String raise PlanError {
  let fields = moon_config_object(content)
  fields["registry"] = Json::string(registry)
  fields["index"] = Json::string(index)
  fields["symbols"] = Json::string(symbols)
  Json::object(fields).stringify(indent=2) + "\n"
}

///|
pub fn reset_mooncakes_mirror_config(
  content : String,
) -> String raise PlanError {
  let fields = moon_config_object(content)
  fields.remove("registry")
  fields.remove("index")
  fields.remove("symbols")
  if fields.is_empty() {
    ""
  } else {
    Json::object(fields).stringify(indent=2) + "\n"
  }
}

///|
pub fn get_mooncakes_mirror_config(content : String) -> String? raise PlanError {
  match moon_config_object(content).get("registry") {
    Some(String(registry)) => Some(registry)
    Some(_) =>
      raise ConfigConflict(
        path="MoonBit config.json",
        detail="registry field must be a string",
      )
    None => None
  }
}
