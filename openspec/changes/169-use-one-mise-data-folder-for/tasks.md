# Tasks

## 1. Drop the mise data folder export from the README Tools block

Kind: other. Reads: `README.md`, `AGENTS.md`, `.pre-commit-config.yaml`. Changes: `README.md`.

- [ ] 1.1 Remove the export line `README.md:270:export MISE_DATA_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/infra-tools/mise"` from the `sh` block of the Tools section of `README.md`. Rewrite the sentence that ends at `README.md:266:check-jsonschema, Copier, pre-commit, yamllint and zizmor). Install them into one shared cache`, so it says that `mise install --locked` writes the binary tools into the default mise data folder and `uv sync --frozen` writes the Python tools into `.venv`. Keep the two commands of the block at `README.md:271:mise install --locked` and `README.md:272:uv sync --frozen` and the rest of the Tools section as they are
  - Verification: `$ ! git grep -n MISE_DATA_DIR README.md` passes
- [ ] 1.2 Edit `README.md`, section Tools, to drop the `MISE_DATA_DIR` export and to name the default mise data folder of `mise install --locked`
  - Verification: `$ uv run devops ci docs` passes

## 2. Say in the Pre-commit hooks section that the hook uses the default mise data folder, and run the live check

Kind: other. Reads: `README.md`, `.pre-commit-config.yaml`, `mise.toml`. Changes: `README.md`.

- [ ] 2.1 Add one sentence to the Pre-commit hooks section of `README.md`, after `README.md:315:After `uv sync --frozen`, run `.venv/bin/pre-commit install` once in each clone. The hooks of`, saying that the gitleaks hook runs `mise exec` and finds each tool in the default mise data folder that the Tools section installs into, so a new shell sets no variable. Then run the manual check of the process in a new shell that sets no `MISE_DATA_DIR`: `test -z "${MISE_DATA_DIR-}"`, `mise install --locked`, `mise ls --missing` prints nothing, and `.venv/bin/pre-commit run gitleaks` passes, and run this check by hand: In a new shell with no MISE_DATA_DIR, run `test -z "${MISE_DATA_DIR-}"`, then `mise install --locked`, then `mise ls --missing` and confirm that it prints nothing, then `.venv/bin/pre-commit run gitleaks` and confirm that the hook passes.
- [ ] 2.2 Edit `README.md`, section Pre-commit hooks, to say that the gitleaks hook uses the default mise data folder
  - Verification: `$ uv run devops ci docs` passes
