# Changelog

All notable changes to MoonChsrc are documented here. The project follows
[Semantic Versioning](https://semver.org/).

## 0.1.0 - 2026-09-23

### Added

- Recipe-driven support for npm, pnpm, Yarn 2+, Node.js, pip, Go modules,
  Composer, Cargo, MoonBit/mooncakes, and RubyGems.
- `list`, `get`, `set`, `reset`, `restore`, and `measure` commands.
- Concurrent HTTPS mirror measurement and automatic fastest-source selection.
- Preview-first `--dry-run` plans, local snapshots, credential redaction, and
  rollback after partial failures.
- Typed, atomic configuration editing for Cargo and MoonBit.
- Native builds and checksum-verifying installers for Linux, macOS, and Windows.
