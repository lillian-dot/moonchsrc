///|
fn quote_argument(value : String) -> String {
  if value.any(char => char == ' ' || char == '\t') {
    "\"" + value + "\""
  } else {
    value
  }
}

///|
pub fn Command::to_text(self : Command) -> String {
  let args = self.args.map(quote_argument).iter().join(" ")
  if args == "" {
    self.program
  } else {
    "\{self.program} \{args}"
  }
}

///|
pub fn ConfigPath::to_text(self : ConfigPath) -> String {
  match self {
    CargoProject => ".cargo/config.toml"
    CargoUser => "$CARGO_HOME/config.toml"
    MoonUser => "$MOON_HOME/config.json"
  }
}

///|
pub fn FileStep::to_text(self : FileStep) -> String {
  match self.operation {
    ReadCargoSource => "read Cargo source from \{self.path.to_text()}"
    SetCargoSource(url) =>
      "set Cargo source in \{self.path.to_text()} to \{url}"
    ResetCargoSource =>
      "remove MoonChsrc Cargo source from \{self.path.to_text()}"
    RestoreContent(Present(_)) =>
      "restore previous content of \{self.path.to_text()}"
    RestoreContent(Missing) =>
      "remove \{self.path.to_text()} (previously absent)"
    RestoreContent(Redacted) =>
      "refuse redacted restore for \{self.path.to_text()}"
    ReadMooncakesSource => "read mooncakes source from \{self.path.to_text()}"
    SetMooncakesSource(registry~, index~, symbols~) =>
      "set mooncakes source in \{self.path.to_text()} to registry=\{registry}, index=\{index}, symbols=\{symbols}"
    ResetMooncakesSource =>
      "remove MoonChsrc mooncakes source from \{self.path.to_text()}"
  }
}

///|
pub fn ChangePlan::to_text(self : ChangePlan) -> String {
  let commands = self.commands.map(command => "$ \{command.to_text()}")
  let files = self.file_steps.map(step => "$ [file] \{step.to_text()}")
  let steps = commands
  for file in files {
    steps.push(file)
  }
  let mirror = match self.mirror_id {
    Some(id) => "\nmirror: \{id}"
    None => ""
  }
  "operation: \{self.operation.to_text()}\ntarget: \{self.target_id}\{mirror}\nscope: \{self.scope.to_text()}\n\{steps.iter().join("\n")}"
}

///|
pub fn render_measurements(measurements : ArrayView[Measurement]) -> String {
  measurements
  .map(measurement => {
    match (measurement.latency_ms, measurement.http_status) {
      (Some(latency), Some(status)) =>
        "\{measurement.mirror_id}\t\{latency} ms\tHTTP \{status}\t\{measurement.url}"
      _ => "\{measurement.mirror_id}\ttimeout/error\t\{measurement.url}"
    }
  })
  .iter()
  .join("\n")
}

///|
pub fn render_mirrors() -> String {
  let lines = mirrors().map(mirror => "\{mirror.id}\t\{mirror.name}")
  "Available mirrors:\n\{lines.iter().join("\n")}"
}

///|
pub fn render_targets() -> String {
  let lines = targets().map(target => {
    let aliases = if target.aliases.is_empty() {
      "-"
    } else {
      target.aliases.iter().join(", ")
    }
    "\{target.id}\t\{target.name}\taliases: \{aliases}"
  })
  "Available targets:\n\{lines.iter().join("\n")}"
}

///|
pub fn render_target(name : StringView) -> String raise PlanError {
  let target = match find_target(name) {
    Some(target) => target
    None => raise UnknownTarget(name.to_owned())
  }
  let sources = target.sources
    .map(source => "  \{source.mirror_id}\t\{source.url}")
    .iter()
    .join("\n")
  let scopes = target.scopes.map(scope => scope.to_text()).iter().join(", ")
  let capabilities = target.capabilities
    .map(capability => capability.to_text())
    .iter()
    .join(", ")
  "\{target.id} - \{target.name}\naliases: \{target.aliases.iter().join(", ")}\nscopes: \{scopes}\ncapabilities: \{capabilities}\nsources:\n\{sources}"
}
