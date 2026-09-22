# Contributing to MoonChsrc

Thank you for helping improve MoonChsrc. Bug reports, mirror corrections, new
recipes, tests, and documentation are all welcome.

## Development setup

Install the current MoonBit toolchain, clone the repository, then run:

```text
moon update
moon check --target native --warn-list +unnecessary_annotation
moon test --target native
moon info
moon fmt
```

The last two commands regenerate public interfaces and normalize formatting.
Commit any resulting changes.

## Making a change

1. Keep recipe rules in the recipe/planner layer and operating-system side
   effects in `internal/` packages.
2. Add tests for successful plans, aliases, unsupported scopes, and restore
   behavior.
3. Never put real credentials or personal configuration into fixtures.
4. Update the README and changelog when behavior visible to users changes.
5. Run the complete quality gate before opening a pull request.

See [docs/RECIPES.md](docs/RECIPES.md) for the recipe checklist and
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for component boundaries.

## Reporting security issues

Do not publish credentials or sensitive configuration in a public issue. A
report should contain the smallest redacted reproduction that demonstrates the
problem.
