# Design

## Decisions

- **Drop the `MISE_DATA_DIR` export from the README instead of setting the variable in the hook entry.**: mise keeps each tool version apart in its default folder, so repositories that pin the same version share one copy there, and no shell setup is needed; `.pre-commit-config.yaml:18:entry: mise exec -- scripts/private-data-scan.sh git --pre-commit --staged` runs no shell, so a variable set there needs a wrapper for the expansion of `XDG_CACHE_HOME`.
- **Keep the gitleaks hook entry unchanged.**: `references` for `MISE_DATA_DIR` answered `files 1, lines 1.` in `README.md`, so the hook already uses the default folder and the README edit alone makes the document and the hook agree; CI already installs that way at `.github/workflows/ci.yml:145:run: mise install --locked gitleaks`.
- **Split the work into two groups: the README Tools edit with a negative search, then the Pre-commit hooks sentence with the manual live check.**: the live check needs `mise`, a checkout and a network, which the runner pod lacks, so it stays a manual step of a person; the negative search needs only `git` and the checkout, so the document edit is proven on each run.
- **Document in the Pre-commit hooks section that the hook uses the default mise data folder.**: `read_file` of `README.md` lines 305 to 320 showed that the section starts at `README.md:315:After `uv sync --frozen`, run `.venv/bin/pre-commit install` once in each clone. The hooks of` and names no data folder, so a reader cannot tell which folder the hook uses; the sentence makes the one-folder behavior visible.

## Rejected alternatives

- **Keep the README export and add `MISE_DATA_DIR` to the gitleaks hook entry.**: `.pre-commit-config.yaml:18:entry: mise exec -- scripts/private-data-scan.sh git --pre-commit --staged` runs no shell, so the entry cannot expand `XDG_CACHE_HOME` without a wrapper, and each new shell still needs the export of `README.md:270:export MISE_DATA_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/infra-tools/mise"`.
- **Add a wrapper script that exports the cache data folder before `mise exec` in the hook.**: `references` for `MISE_DATA_DIR` answered `files 1, lines 1.`, so the wrapper is a new file that both the README and the hook must name, and the cache copy of the tools stays; `mise.toml:9:gitleaks = "8.30.1"` pins the version that the default folder already holds.
- **Prove the change with only a live hook check.**: a live check does not show that the README no longer tells the reader to set the variable; `references` for `MISE_DATA_DIR` answered `files 1, lines 1.` with `README.md: 1 (line 270)`, so the negative search is the check that covers the document.
- **Prove the change with only a grep of `README.md`.**: a grep does not show that the hook finds the tools in the default folder; `.github/workflows/ci.yml:145:run: mise install --locked gitleaks` shows CI already installs that way, but only the live check runs the hook itself.
