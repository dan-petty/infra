## Purpose
The settings baseline schema and the Copier template of a new repository: the Pages site, the collaborators and the environment that publishes the site.

## ADDED Requirements

### Requirement: The settings schema names a Pages site
The repository settings schema SHALL name a `pages` object with a required `build_type` of `legacy` or `workflow`, an optional `source` with a required `branch` and a `path` of `/` or `/docs`, an optional `cname` that is a string or null, and an optional boolean `https_enforced`. It SHALL require `source` when `build_type` is `legacy`, and SHALL refuse each field that it does not name.

#### Scenario: The rendered Pages site passes the schema
- **WHEN** After `uv sync --frozen`, `uv run copier copy --quiet --defaults --vcs-ref HEAD --data infra_ref=v1.2.3 --data pages=true --data collaborators=example-user:push . /tmp/pages` renders the working tree from the repository root with no network.
- **THEN** `uv run check-jsonschema --check-metaschema templates/github-repository.schema.json` and `uv run check-jsonschema --schemafile templates/github-repository.schema.json /tmp/pages/github/repository.yaml` exit with status 0.

#### Scenario: The schema refuses an invalid Pages site
- **WHEN** After `uv sync --frozen` and `mise install --locked`, `yq` sets the `pages` key of the settings file of the default render, and `uv run check-jsonschema --schemafile templates/github-repository.schema.json` checks the file with no network.
- **THEN** The command exits with status 1 for `{"build_type": "legacy"}` and for `{"build_type": "workflow", "buildtype": "workflow"}`, and with status 0 for `{"build_type": "legacy", "source": {"branch": "main", "path": "/docs"}}`.

### Requirement: The settings schema names the collaborators
The repository settings schema SHALL name a `collaborators` array whose items hold a required `username` and a required `permission` of `pull`, `triage`, `moderate`, `push`, `maintain` or `admin`, and SHALL refuse each field of an item that it does not name.

#### Scenario: The rendered collaborator passes the schema
- **WHEN** After `uv sync --frozen`, `uv run copier copy --quiet --defaults --vcs-ref HEAD --data infra_ref=v1.2.3 --data pages=true --data collaborators=example-user:push . /tmp/pages` renders the working tree from the repository root with no network.
- **THEN** `uv run check-jsonschema --schemafile templates/github-repository.schema.json /tmp/pages/github/repository.yaml` exits with status 0.

#### Scenario: The schema refuses an unknown collaborator field
- **WHEN** After `uv sync --frozen` and `mise install --locked`, `yq` sets the `collaborators` key of the settings file of the default render to `[{"username": "example-user", "permission": "push", "role": "write"}]`, and `uv run check-jsonschema --schemafile templates/github-repository.schema.json` checks the file with no network.
- **THEN** The command exits with status 1.

### Requirement: The pages answer renders the site and its environment
The template SHALL render the `pages` key with `build_type: workflow` and the environment `github-pages` with the branch policy `main` when the `pages` answer is true.

#### Scenario: The pages answer renders the site and the environment
- **WHEN** After `uv sync --frozen`, `uv run copier copy --quiet --defaults --vcs-ref HEAD --data infra_ref=v1.2.3 --data pages=true --data collaborators=example-user:push . /tmp/pages` renders the working tree from the repository root with no network.
- **THEN** The rendered settings file holds `pages` with `build_type: workflow` and the one environment `github-pages` with `protected_branches: false`, `custom_branch_policies: true` and the branch policy `main`, and `uv run check-jsonschema --schemafile templates/github-repository.schema.json /tmp/pages/github/repository.yaml` exits with status 0.

### Requirement: The collaborators answer renders each collaborator
The template SHALL render each `username:permission` pair of the `collaborators` answer as an item of `collaborators` with the `username` and the `permission` of the pair.

#### Scenario: A collaborator answer renders one collaborator
- **WHEN** After `uv sync --frozen`, `uv run copier copy --quiet --defaults --vcs-ref HEAD --data infra_ref=v1.2.3 --data pages=true --data collaborators=example-user:push . /tmp/pages` renders the working tree from the repository root with no network.
- **THEN** The rendered settings file holds `collaborators` with the one item `username: example-user` and `permission: push`, and `uv run check-jsonschema --schemafile templates/github-repository.schema.json /tmp/pages/github/repository.yaml` exits with status 0.

### Requirement: The default answers render no site and no collaborator
The template SHALL render no `pages` key, no `collaborators` key and no `environments` key with the default answers, so an empty `collaborators` answer names no collaborator set.

#### Scenario: The default render holds no site and no collaborator
- **WHEN** After `uv sync --frozen`, `uv run copier copy --quiet --defaults --vcs-ref HEAD --data infra_ref=v1.2.3 . /tmp/defaults` renders the working tree from the repository root with no network.
- **THEN** The rendered settings file holds no `pages` key, no `collaborators` key and no `environments` key, and `uv run check-jsonschema --schemafile templates/github-repository.schema.json /tmp/defaults/github/repository.yaml` exits with status 0.

### Requirement: Copier refuses an invalid collaborator answer
Copier MUST refuse a `collaborators` answer that is not a `username:permission` pair with a permission of `pull`, `triage`, `moderate`, `push`, `maintain` or `admin`.

#### Scenario: Copier refuses an unknown permission
- **WHEN** After `uv sync --frozen`, `uv run copier copy --quiet --defaults --vcs-ref HEAD --data infra_ref=v1.2.3 --data collaborators=example-user:owner . /tmp/refused` runs from the repository root with no network.
- **THEN** The command exits with status 1 and prints `Validation error for question 'collaborators'`.

### Requirement: The template holds no private value
The template, its schema and its test SHALL hold no secret value and SHALL name each example repository and collaborator with a public example.

#### Scenario: The private-data guard finds no secret
- **WHEN** After `uv sync --frozen` and `mise install --locked`, `mise exec -- tests/test-private-data-scan.sh` and `mise exec -- scripts/private-data-scan.sh dir .` run from the repository root.
- **THEN** Both commands exit with status 0, and the guard prints no finding.
