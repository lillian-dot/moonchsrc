# Recipe authoring guide

A recipe describes one developer tool without teaching the CLI or executor its
name. Recipes are registered in `recipe.mbt`; small command constructors live
near the planner code, while structured configuration editors have dedicated
modules.

## Required behavior

Every target should provide:

- stable target ID, aliases, supported scopes, and capabilities;
- an official source and at least one usable mirror;
- get, set, reset, and snapshot restore behavior;
- a credential-free HTTPS endpoint for measurement;
- tests for aliases, scopes, plans, errors, and restore values.

Command-based recipes return `Command` values. Do not invoke a shell or encode
multiple commands in one string. File-based recipes return typed `FileStep`
values and must preserve unrelated user configuration.

## Adding a target

1. Add mirrors and source endpoints to the catalog.
2. Implement small command or file-step constructors.
3. Register one `Recipe` with capture, set, get, reset, and restore functions.
4. Add planner tests and, for file formats, parser/editor tests.
5. Add the target to the README support table and changelog.
6. Run the full quality gate in `CONTRIBUTING.md`.

## Safety rules

- A write must have a restorable snapshot before it starts.
- Treat URLs containing user information or authentication parameters as
  sensitive; do not persist them in clear text.
- Use atomic same-directory replacement for configuration files.
- Refuse malformed or conflicting configuration rather than overwriting it.
- Ensure dry-run renders the exact affected tool, scope, and path.
