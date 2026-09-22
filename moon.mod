// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "trail-it/moonchsrc"

version = "0.2.0-dev"

readme = "README.mbt.md"

repository = "https://github.com/trail-it/moonchsrc"

license = "Apache-2.0"

keywords = [ "mirror", "registry", "cli", "developer-tools" ]

preferred_target = "native"

description = "A MoonBit-native, preview-first source and registry switcher"

import {
  "moonbitlang/x@0.5.5",
  "moonbitlang/async@0.21.3",
}
