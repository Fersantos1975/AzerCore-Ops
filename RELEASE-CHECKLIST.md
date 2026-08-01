# Release checklist

Use this checklist before tagging any AzerCore Ops release.

## Source and documentation

- [ ] Version matches in `CMakeLists.txt`, `addon/AzerCoreOps/AzerCoreOps.toc`, addon runtime metadata, `CHANGELOG.md`, and `RELEASE-NOTES.md`.
- [ ] Release channel and capability list are accurate.
- [ ] README installation commands use portable placeholders rather than machine-specific paths.
- [ ] No credentials, personal filesystem paths, private hostnames, or local network addresses are present.
- [ ] Changelog and release notes describe only functionality included in the release.
- [ ] `tools/azercoreops-check` passes.

## Module build

- [ ] Repository is located at `<azerothcore-root>/modules/mod-azercore-ops`.
- [ ] AzerothCore is reconfigured after source changes.
- [ ] Static module build succeeds.
- [ ] Dynamic module build is tested when claimed as supported.
- [ ] Install target completes successfully.
- [ ] Worldserver starts without AzerCore Ops errors.
- [ ] Build information reports the expected module, core, and playerbots revisions.

## Addon validation

- [ ] Addon loads without Lua errors on a clean 3.3.5a client profile.
- [ ] Saved settings initialize correctly.
- [ ] Minimap button and Interface Options entries work.
- [ ] Main window opens, closes, minimizes, and restores correctly.
- [ ] Quest search works by numeric ID and title.
- [ ] Quest details render without malformed protocol output.
- [ ] SELF and TARGET contexts work as expected.
- [ ] Inspect Quest Log loads every active quest for the selected online player.
- [ ] Target Quest Log handles target changes, refresh, empty logs, no target, copy, share, and export.
- [ ] Group audit handles solo, party, and raid states safely.
- [ ] Search history, activity log, copy, and export functions work.
- [ ] Instance inspection commands still respond correctly.
- [ ] Structured My Binds and Target Binds show exact Instance IDs and reset metadata.
- [ ] Boss progress shows defeated/total counts and defeated/remaining names when available.
- [ ] Group Audit identifies same-ID, different-ID, no-bind, blocked, and offline members correctly.
- [ ] Non-applicable bind selection explains why without selecting the bind.
- [ ] Multi-select batch unbind requires confirmation and reports every success or failure in Bind Activity.
- [ ] Post-unbind target reinspection confirms that successfully removed binds are gone.

## Release publication

- [ ] Commit history is clean and the release commit is on `main`.
- [ ] Release tag uses the form `vX.Y.Z` or an approved prerelease suffix.
- [ ] GitHub release notes match `RELEASE-NOTES.md`.
- [ ] Release archive contains only required source, addon, documentation, assets, and tools.
- [ ] Installation instructions were tested from a fresh checkout.
