///|
/// Configuration scope supported by a target recipe.
pub(all) enum Scope {
  Project
  User
  System
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn Scope::to_text(self : Scope) -> String {
  match self {
    Project => "project"
    User => "user"
    System => "system"
  }
}

///|
pub fn Scope::parse(text : StringView) -> Scope? {
  match text.to_owned().to_lower() {
    "project" => Some(Project)
    "user" => Some(User)
    "system" | "global" => Some(System)
    _ => None
  }
}

///|
/// A public mirror provider.
pub(all) struct Mirror {
  id : String
  name : String
} derive(Debug, Eq)

///|
/// A mirror endpoint supported by one target.
pub(all) struct Source {
  mirror_id : String
  url : String
} derive(Debug, Eq)

///|
/// Operations implemented by a target recipe.
pub(all) enum Capability {
  CanGet
  CanSet
  CanReset
  CanMeasure
} derive(Debug, Eq)

///|
pub fn Capability::to_text(self : Capability) -> String {
  match self {
    CanGet => "get"
    CanSet => "set"
    CanReset => "reset"
    CanMeasure => "measure"
  }
}

///|
/// A package manager or developer tool whose source can be changed.
pub(all) struct Target {
  id : String
  name : String
  aliases : Array[String]
  scopes : Array[Scope]
  capabilities : Array[Capability]
  sources : Array[Source]
} derive(Debug, Eq)

///|
/// A process invocation represented without shell interpolation.
pub(all) struct Command {
  program : String
  args : Array[String]
} derive(Debug, Eq)

///|
/// A platform-neutral configuration path resolved by the native executor.
pub(all) enum ConfigPath {
  CargoProject
  CargoUser
  MoonUser
} derive(Debug, Eq)

///|
/// File operations stay typed so dry-run rendering and execution never rely
/// on shell redirection or text-substitution commands.
pub(all) enum FileOperation {
  ReadCargoSource
  SetCargoSource(String)
  ResetCargoSource
  RestoreContent(SavedValue)
  ReadMooncakesSource
  SetMooncakesSource(registry~ : String, index~ : String, symbols~ : String)
  ResetMooncakesSource
} derive(Debug, Eq)

///|
pub(all) struct FileStep {
  path : ConfigPath
  operation : FileOperation
} derive(Debug, Eq)

///|
/// Result of probing one mirror endpoint. Missing latency/status means that
/// the request failed or exceeded its timeout.
pub(all) struct Measurement {
  mirror_id : String
  url : String
  latency_ms : Int64?
  http_status : Int?
} derive(Debug, Eq)

///|
/// The source-changing operation represented by a plan.
pub(all) enum Operation {
  GetSource
  SetSource
  ResetSource
  RestoreSource
} derive(Debug, Eq)

///|
pub fn Operation::to_text(self : Operation) -> String {
  match self {
    GetSource => "get"
    SetSource => "set"
    ResetSource => "reset"
    RestoreSource => "restore"
  }
}

///|
/// A resolved source-change operation.
pub(all) struct ChangePlan {
  operation : Operation
  target_id : String
  mirror_id : String?
  scope : Scope
  commands : Array[Command]
  file_steps : Array[FileStep]
} derive(Debug, Eq)

///|
/// A parsed CLI request. Execution is kept separate from argument parsing so
/// tests never need to launch external processes.
pub(all) enum CliAction {
  Show(String)
  Execute(ChangePlan)
  RestoreLatest(String, Scope, Bool)
  MeasureTarget(String)
  AutoSelect(String, Scope, Bool)
} derive(Debug, Eq)

///|
pub(all) suberror PlanError {
  UnknownTarget(String)
  UnknownMirror(target~ : String, mirror~ : String)
  InvalidScope(String)
  UnsupportedScope(target~ : String, scope~ : Scope)
  InvalidSnapshot(target~ : String, expected~ : Int, actual~ : Int)
  SnapshotNotRestorable(String)
  NoSelectableMirror(String)
  ConfigConflict(path~ : String, detail~ : String)
  UnsafeConfigValue(String)
} derive(Debug, Eq)
