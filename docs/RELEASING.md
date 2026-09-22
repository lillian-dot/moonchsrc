# Release process

MoonChsrc uses the module version without a leading `v` and matching Git tags
with a leading `v`.

1. Update `moon.mod`, `moonchsrc.mbt`, and `CHANGELOG.md` to the same version.
2. Run the complete local quality gate and `moon publish --dry-run`.
3. Commit and push the release state; wait for the CI workflow to pass.
4. Tag the commit as `vX.Y.Z` and push the tag.
5. The Release workflow builds native binaries, publishes SHA-256 checksums,
   and creates the GitHub release.
6. Test one installer against the release.
7. Run `moon publish --frozen`, then verify the module is discoverable on
   mooncakes.io.

Do not reuse or move a published tag. If a release needs correction, publish a
new patch version.
