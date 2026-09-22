///|
/// Built-in mirror providers known to MoonChsrc.
pub fn mirrors() -> Array[Mirror] {
  [
    { id: "official", name: "Official upstream", },
    { id: "npmmirror", name: "npmmirror", },
    { id: "tuna", name: "Tsinghua TUNA", },
    { id: "ustc", name: "USTC Mirrors", },
    { id: "goproxycn", name: "goproxy.cn", },
    { id: "aliyun", name: "Alibaba Cloud Mirrors", },
    { id: "rsproxy", name: "RsProxy", },
    { id: "rubychina", name: "Ruby China", },
    { id: "sjtug", name: "Shanghai Jiao Tong University Mirrors", },
  ]
}

///|
/// Built-in target recipes.
pub fn targets() -> Array[Target] {
  recipes().map(recipe => recipe.target)
}

///|
pub fn find_target(name : StringView) -> Target? {
  let query = name.to_owned().to_lower()
  let all = targets()
  match
    all.search_by(target => target.id == query || target.aliases.contains(query)) {
    Some(index) => Some(all[index])
    None => None
  }
}

///|
pub fn find_mirror(id : StringView) -> Mirror? {
  let query = id.to_owned().to_lower()
  let all = mirrors()
  match all.search_by(mirror => mirror.id == query) {
    Some(index) => Some(all[index])
    None => None
  }
}

///|
fn Target::find_source(self : Target, mirror_id : String) -> Source? {
  match self.sources.search_by(source => source.mirror_id == mirror_id) {
    Some(index) => Some(self.sources[index])
    None => None
  }
}
