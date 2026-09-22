///|
/// A recipe owns target metadata and the functions that produce commands.
/// Adding a target means registering one value here; the planner and CLI do
/// not dispatch on target identifiers.
priv struct Recipe {
  target : Target
  set_commands : (Source, Scope) -> Array[Command]
  get_commands : (Scope) -> Array[Command]
  restore_commands : (ArrayView[SavedValue], Scope) -> Array[Command] raise PlanError
  capture_command : (Int, StringView) -> SavedValue
  set_file_steps : (Source, Scope) -> Array[FileStep]
  get_file_steps : (Scope) -> Array[FileStep]
  restore_file_steps : (ArrayView[SavedValue], Scope) -> Array[FileStep]
}

///|
fn no_set_file_steps(_source : Source, _scope : Scope) -> Array[FileStep] {
  []
}

///|
fn no_get_file_steps(_scope : Scope) -> Array[FileStep] {
  []
}

///|
fn no_restore_file_steps(
  _values : ArrayView[SavedValue],
  _scope : Scope,
) -> Array[FileStep] {
  []
}

///|
fn recipes() -> Array[Recipe] {
  [
    {
      target: {
        id: "npm",
        name: "npm registry",
        aliases: [],
        scopes: [Project, User, System],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://registry.npmjs.org/", },
          { mirror_id: "npmmirror", url: "https://registry.npmmirror.com/", },
        ],
      },
      set_commands: (source, scope) => [npm_command(source, scope)],
      get_commands: scope => [npm_get_command(scope)],
      restore_commands: (values, scope) => {
        require_snapshot_size("npm", values, 1)
        [npm_restore_command(values[0], scope)]
      },
      capture_command: capture_value,
      set_file_steps: no_set_file_steps,
      get_file_steps: no_get_file_steps,
      restore_file_steps: no_restore_file_steps,
    },
    {
      target: {
        id: "pnpm",
        name: "pnpm registry",
        aliases: [],
        scopes: [Project, User],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://registry.npmjs.org/", },
          { mirror_id: "npmmirror", url: "https://registry.npmmirror.com/", },
        ],
      },
      set_commands: (source, scope) => [pnpm_command(source, scope)],
      get_commands: scope => [pnpm_get_command(scope)],
      restore_commands: (values, scope) => {
        require_snapshot_size("pnpm", values, 1)
        [pnpm_restore_command(values[0], scope)]
      },
      capture_command: capture_value,
      set_file_steps: no_set_file_steps,
      get_file_steps: no_get_file_steps,
      restore_file_steps: no_restore_file_steps,
    },
    {
      target: {
        id: "yarn",
        name: "Yarn registry (Yarn 2+)",
        aliases: [],
        scopes: [Project, User],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://registry.yarnpkg.com/", },
          { mirror_id: "npmmirror", url: "https://registry.npmmirror.com/", },
        ],
      },
      set_commands: (source, scope) => [yarn_command(source, scope)],
      get_commands: _ => [yarn_get_command()],
      restore_commands: (values, scope) => {
        require_snapshot_size("yarn", values, 1)
        [yarn_restore_command(values[0], scope)]
      },
      capture_command: capture_value,
      set_file_steps: no_set_file_steps,
      get_file_steps: no_get_file_steps,
      restore_file_steps: no_restore_file_steps,
    },
    {
      target: {
        id: "node",
        name: "Node.js package manager registries",
        aliases: ["nodejs"],
        scopes: [Project, User],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://registry.npmjs.org/", },
          { mirror_id: "npmmirror", url: "https://registry.npmmirror.com/", },
        ],
      },
      set_commands: (source, scope) => {
        [
          npm_command(source, scope),
          pnpm_command(source, scope),
          yarn_command(source, scope),
        ]
      },
      get_commands: scope => {
        [npm_get_command(scope), pnpm_get_command(scope), yarn_get_command()]
      },
      restore_commands: (values, scope) => {
        require_snapshot_size("node", values, 3)
        [
          npm_restore_command(values[0], scope),
          pnpm_restore_command(values[1], scope),
          yarn_restore_command(values[2], scope),
        ]
      },
      capture_command: capture_value,
      set_file_steps: no_set_file_steps,
      get_file_steps: no_get_file_steps,
      restore_file_steps: no_restore_file_steps,
    },
    {
      target: {
        id: "pip",
        name: "Python package index",
        aliases: ["python", "pypi"],
        scopes: [Project, User, System],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://pypi.org/simple", },
          {
            mirror_id: "tuna",
            url: "https://pypi.tuna.tsinghua.edu.cn/simple",
          },
          { mirror_id: "ustc", url: "https://pypi.mirrors.ustc.edu.cn/simple", },
        ],
      },
      set_commands: (source, scope) => [pip_command(source, scope)],
      get_commands: scope => [pip_get_command(scope)],
      restore_commands: (values, scope) => {
        require_snapshot_size("pip", values, 1)
        [pip_restore_command(values[0], scope)]
      },
      capture_command: capture_value,
      set_file_steps: no_set_file_steps,
      get_file_steps: no_get_file_steps,
      restore_file_steps: no_restore_file_steps,
    },
    {
      target: {
        id: "go",
        name: "Go module proxy",
        aliases: ["golang"],
        scopes: [User],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://proxy.golang.org,direct", },
          { mirror_id: "goproxycn", url: "https://goproxy.cn,direct", },
        ],
      },
      set_commands: (source, _) => [go_command(source)],
      get_commands: _ => [go_get_command()],
      restore_commands: (values, _) => {
        require_snapshot_size("go", values, 1)
        [go_restore_command(values[0])]
      },
      capture_command: capture_value,
      set_file_steps: no_set_file_steps,
      get_file_steps: no_get_file_steps,
      restore_file_steps: no_restore_file_steps,
    },
    {
      target: {
        id: "composer",
        name: "PHP Composer repository",
        aliases: ["packagist"],
        scopes: [Project, User],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://repo.packagist.org", },
          { mirror_id: "aliyun", url: "https://mirrors.aliyun.com/composer/", },
        ],
      },
      set_commands: (source, scope) => [composer_command(source, scope)],
      get_commands: scope => [composer_get_command(scope)],
      restore_commands: (values, scope) => {
        require_snapshot_size("composer", values, 1)
        [composer_restore_command(values[0], scope)]
      },
      capture_command: capture_value,
      set_file_steps: no_set_file_steps,
      get_file_steps: no_get_file_steps,
      restore_file_steps: no_restore_file_steps,
    },
    {
      target: {
        id: "cargo",
        name: "Rust Cargo registry",
        aliases: ["rust", "crate", "crates"],
        scopes: [Project, User],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://index.crates.io/", },
          { mirror_id: "rsproxy", url: "https://rsproxy.cn/index/", },
          {
            mirror_id: "ustc",
            url: "https://mirrors.ustc.edu.cn/crates.io-index/",
          },
        ],
      },
      set_commands: (_, _) => [],
      get_commands: _ => [],
      restore_commands: (values, _) => {
        require_snapshot_size("cargo", values, 1)
        []
      },
      capture_command: capture_value,
      set_file_steps: cargo_set_file_steps,
      get_file_steps: cargo_get_file_steps,
      restore_file_steps: cargo_restore_file_steps,
    },
    {
      target: {
        id: "mooncakes",
        name: "MoonBit package registry",
        aliases: ["moon", "moonbit"],
        scopes: [User],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://mooncakes.io", },
          { mirror_id: "ustc", url: "https://mirrors.ustc.edu.cn/mooncakes", },
        ],
      },
      set_commands: (_, _) => [],
      get_commands: _ => [],
      restore_commands: (values, _) => {
        require_snapshot_size("mooncakes", values, 1)
        []
      },
      capture_command: capture_value,
      set_file_steps: moon_set_file_steps,
      get_file_steps: moon_get_file_steps,
      restore_file_steps: moon_restore_file_steps,
    },
    {
      target: {
        id: "rubygems",
        name: "RubyGems sources",
        aliases: ["ruby", "gem", "rb"],
        scopes: [User],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://rubygems.org/", },
          { mirror_id: "rubychina", url: "https://gems.ruby-china.com/", },
        ],
      },
      set_commands: (source, _) => rubygems_set_commands(source),
      get_commands: _ => [rubygems_get_command()],
      restore_commands: (values, _) => {
        require_snapshot_size("rubygems", values, 1)
        rubygems_restore_commands(values[0])
      },
      capture_command: capture_rubygems_sources,
      set_file_steps: no_set_file_steps,
      get_file_steps: no_get_file_steps,
      restore_file_steps: no_restore_file_steps,
    },
    {
      target: {
        id: "flathub",
        name: "Flathub Flatpak remote",
        aliases: ["flatpak"],
        scopes: [User, System],
        capabilities: [CanGet, CanSet, CanReset, CanMeasure],
        sources: [
          { mirror_id: "official", url: "https://dl.flathub.org/repo", },
          { mirror_id: "ustc", url: "https://mirrors.ustc.edu.cn/flathub", },
          {
            mirror_id: "sjtug",
            url: "https://mirrors.sjtug.sjtu.edu.cn/flathub",
          },
        ],
      },
      set_commands: (source, scope) => [flatpak_command(source, scope)],
      get_commands: scope => [flatpak_get_command(scope)],
      restore_commands: (values, scope) => {
        require_snapshot_size("flathub", values, 1)
        [flatpak_restore_command(values[0], scope)]
      },
      capture_command: capture_flathub_url,
      set_file_steps: no_set_file_steps,
      get_file_steps: no_get_file_steps,
      restore_file_steps: no_restore_file_steps,
    },
  ]
}

///|
fn find_recipe(name : StringView) -> Recipe? {
  let query = name.to_owned().to_lower()
  let all = recipes()
  match
    all.search_by(recipe => {
      recipe.target.id == query || recipe.target.aliases.contains(query)
    }) {
    Some(index) => Some(all[index])
    None => None
  }
}

///|
pub fn capture_command_value(
  target_name : StringView,
  exit_code : Int,
  output : StringView,
) -> SavedValue {
  match find_recipe(target_name) {
    Some(recipe) => (recipe.capture_command)(exit_code, output)
    None => capture_value(exit_code, output)
  }
}
