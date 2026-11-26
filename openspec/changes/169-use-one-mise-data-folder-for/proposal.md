# Proposal

## Why

#169 reports that the README (Tools) and the commit hook use different mise data folders, so one devcontainer holds the tools of `mise.toml` twice. The README exports `MISE_DATA_DIR` to a cache folder, and the hook runs `mise exec` with no such variable, so mise installs each missing tool into its default folder. The README gives no reason for a folder of its own, and mise shares one copy of a pinned version among repositories in its default folder.

## What Changes

- Remove the export `README.md:270:export MISE_DATA_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/infra-tools/mise"` from the `sh` block of the Tools section of `README.md`.
- Rewrite the sentence that ends at `README.md:266:check-jsonschema, Copier, pre-commit, yamllint and zizmor). Install them into one shared cache`, so it says that `mise install --locked` writes the binary tools into the default mise data folder and `uv sync --frozen` writes the Python tools into `.venv`.
- Add one sentence to the Pre-commit hooks section of `README.md`, after `README.md:315:After `uv sync --frozen`, run `.venv/bin/pre-commit install` once in each clone. The hooks of`, saying that the gitleaks hook finds each tool in the default mise data folder and needs no variable.
- Leave `.pre-commit-config.yaml` unchanged: its gitleaks entry runs `mise exec` with no data folder variable, so the hook finds the tools in the default mise data folder once the README sets no variable.
- The change has no spec delta: it edits one document, `README.md`, and changes no command, option, workflow, manifest or service behavior.
- Prove the edit with the negative search `! git grep -n MISE_DATA_DIR README.md` and with the manual live check of group 2: in a new shell `mise install --locked`, then `mise ls --missing` prints nothing, and `.venv/bin/pre-commit run gitleaks` passes.
- The change fits one pull request.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None.

## Impact

- Documents: `README.md`

## Feasibility

- The premise of the issue is confirmed: `references` for `MISE_DATA_DIR` answered `References to 'MISE_DATA_DIR': files 1, lines 1.` with `README.md: 1 (line 270)`, and `search_code` for the same name returned one hit, `README.md:270:export MISE_DATA_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/infra-tools/mise"`.
- The probes answer, word for word, The path `README.md` is a file of the staging commit., so the document that this plan edits exists at the staged commit.
- The probes answer, word for word, The path `.pre-commit-config.yaml` is a file of the staging commit. and The path `mise.toml` is a file of the staging commit., so the hook entry and the tool pins that the plan reads exist at the staged commit.
- The probes answer, word for word, The path `AGENTS.md` is a file of the staging commit., and `AGENTS.md:15:7. Install the tools with` names `mise install --locked` and `uv sync --frozen` with no export, so the README edit makes the document agree with the agent rule.
- `read_file` of `README.md` lines 255 to 280 showed the Tools section: the export sits at line 270, and the sentence that must change ends at `README.md:266:check-jsonschema, Copier, pre-commit, yamllint and zizmor). Install them into one shared cache`, so group 1 removes one line and rewrites that sentence.
- `read_file` of `README.md` lines 255 to 280 also showed the two commands of the block at `README.md:271:mise install --locked` and `README.md:272:uv sync --frozen`, and group 1 keeps both.
- `read_file` of `.pre-commit-config.yaml` lines 1 to 22 showed the hook entry at `.pre-commit-config.yaml:18:entry: mise exec -- scripts/private-data-scan.sh git --pre-commit --staged`, which sets no variable, so the hook already runs in the default mise data folder.
- `read_file` of `README.md` lines 305 to 320 showed the Pre-commit hooks section, which names `.pre-commit-config.yaml` and the staged-changes scan and no data folder, so group 2 adds the one-folder sentence there.
- `search_code` for `mise install --locked gitleaks` returned `.github/workflows/ci.yml:145:run: mise install --locked gitleaks`, so CI already installs a tool into the default data folder with no export.
- The staged tree pins the tool that the hook runs: `mise.toml:9:gitleaks = "8.30.1"`, and mise reads that pin from whichever data folder it selects.
- The probe answered, word for word, `MISE_DATA_DIR` has no definition at the staging commit., so no function or constant of the code carries that name and the README export is its only occurrence.
- The probe answered, word for word, Not probed, the bound of 10 commands is reached: `main`, `XDG_CACHE_HOME`, so `XDG_CACHE_HOME` is not probed; it occurs only inside the line that group 1 removes.
- No group changes `scripts/private-data-scan.sh` or `.pre-commit-config.yaml`, so `changes` lists only `README.md`; the hook entry `.pre-commit-config.yaml:18:entry: mise exec -- scripts/private-data-scan.sh git --pre-commit --staged` already runs `mise exec` with no data folder variable, and the plan only reads that file.
- Comment 1 of the issue asks for the scope label `scope/tools` in the labels file: `search_code` for `scope/tools` returned `.github/labels.yml:142:- name: "scope/tools"`, so the label already exists at the staged commit and the plan adds no label.
- The body holds no person-written list under `## Acceptance criteria` before the refine block; the `### Acceptance criteria` heading of the refine block holds two `### Requirement` blocks and no list item, so `criteria` stays empty while group 2 delivers the quoted live check.
- First checks against the real system: in a new shell run `test -z "${MISE_DATA_DIR-}"`, then `! git grep -n MISE_DATA_DIR README.md` from the repository root, then `mise install --locked`, then `mise ls --missing`, which must print nothing, then `.venv/bin/pre-commit run gitleaks`, which must pass.
- Preconditions of those calls: `mise install --locked` needs a checkout of the repository and a network; `mise ls --missing` needs a checkout of the repository; `.venv/bin/pre-commit run gitleaks` needs a checkout of the repository and the `.venv` that `uv sync --frozen` writes.
- Runner capability: `mise` appears in neither the image tools nor the excluded tools of the context, so it is `NOT_IN_RUNNER`; the live check is a manual step of group 2 on a workstation with a checkout and a network, and the pod of the job has a read-only root and no network.
- Runner capability of the verify of group 1: `git` is in the image tools of the context, and `! git grep -n MISE_DATA_DIR README.md` reads the checkout only, so it runs in the pod with a read-only root and no network.
- The verify of group 1 exits 0 only when `README.md` holds no hit; today it exits 1 on the hit at line 270, so it fails before the edit and passes after it.
- The plan relies on no numeric constant of the staged tree, so `constant_claims` is empty; the one pinned version it names is the gitleaks pin of `mise.toml:9:gitleaks = "8.30.1"`.
- No test of the repository asserts the text of `README.md`: `references` for `MISE_DATA_DIR` answered `files 1, lines 1.`, so the change needs no test edit and no change of a CI job.
- Not checked: the sizes 1.3 GB and 2.6 GB of the issue body, because no tool of this run measures a mise data folder.

## Existing Tool Considered

mise (jdx/mise), which `mise.toml` pins and the checks already call, supplies the default data folder `~/.local/share/mise`; the change removes the README export so the README, its `mise exec` commands and the gitleaks hook use that one folder, and it builds no new tool or script.

## Dependencies

None.
