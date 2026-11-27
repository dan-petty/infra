## Purpose
The settings baseline schema and the Copier template of a new repository: the Pages site, the collaborators and the environment that publishes the site.

## ADDED Requirements

### Requirement: The settings schema names a Pages site
The repository settings schema SHALL name a `pages` object with a required `build_type` of `legacy` or `workflow`, an optional `source` with a `branch` and a `path` of `/` or `/docs`, and the optional `cname` and `https_enforced` fields. It SHALL require `source` when `build_type` is `legacy`, and SHALL refuse each field that it does not name.

#### Scenario: The rendered Pages site passes the schema
- **WHEN** After `uv sync --frozen` and `mise install --locked`, `mise exec -- tests/test-repository-template.sh` renders the `pages` case with the answers `pages=true` and `collaborators=example-user:push`.
- **THEN** The test prints `ok   the schema of github/repository.yaml is a valid JSON Schema` and `ok   pages: github/repository.yaml matches its schema`.

### Requirement: The settings schema names the collaborators
The repository settings schema SHALL name a `collaborators` array whose items hold a required `username` and a required `permission` of `pull`, `triage`, `moderate`, `push`, `maintain` or `admin`, and SHALL refuse each field of an item that it does not name.

#### Scenario: The rendered collaborator passes the schema
- **WHEN** After `uv sync --frozen` and `mise install --locked`, `mise exec -- tests/test-repository-template.sh` renders the `pages` case with the answer `collaborators=example-user:push`.
- **THEN** The test prints `ok   pages: github/repository.yaml matches its schema` and `ok   pages: collaborator`.

### Requirement: The pages answer renders the site and its environment
The template SHALL render the `pages` key with `build_type: workflow` and the environment `github-pages` with the branch policy `main` when the `pages` answer is true.

#### Scenario: The pages answer renders the site and the environment
- **WHEN** After `uv sync --frozen` and `mise install --locked`, `mise exec -- tests/test-repository-template.sh` runs the `pages` case.
- **THEN** The test prints `ok   pages: build type` and `ok   pages: github-pages environment`.

### Requirement: The collaborators answer renders each collaborator
The template SHALL render each `username:permission` pair of the `collaborators` answer as an item of `collaborators` with the `username` and the `permission` of the pair.

#### Scenario: A collaborator answer renders one collaborator
- **WHEN** After `uv sync --frozen` and `mise install --locked`, `mise exec -- tests/test-repository-template.sh` runs the `pages` case with the answer `collaborators=example-user:push`.
- **THEN** The test prints `ok   pages: collaborator`.

### Requirement: The default answers render no site and no collaborator
The template SHALL render no `pages` key, no `collaborators` key and no `environments` key with the default answers, so an empty `collaborators` answer names no collaborator set.

#### Scenario: The default render holds no site and no collaborator
- **WHEN** After `uv sync --frozen` and `mise install --locked`, `mise exec -- tests/test-repository-template.sh` runs the `defaults` case.
- **THEN** The test prints `ok   defaults: no pages key`, `ok   defaults: no collaborators key` and `ok   defaults: no environment`.

### Requirement: Copier refuses an invalid collaborator answer
Copier MUST refuse a `collaborators` answer that is not a `username:permission` pair with a permission of `pull`, `triage`, `moderate`, `push`, `maintain` or `admin`.

#### Scenario: Copier refuses an unknown permission
- **WHEN** After `uv sync --frozen` and `mise install --locked`, `mise exec -- tests/test-repository-template.sh` runs the refusal case with the answer `collaborators=example-user:owner`.
- **THEN** The test prints `ok   copier refuses collaborators=example-user:owner`.

### Requirement: The template holds no private value
The template, its schema and its test SHALL hold no secret value and SHALL name each example repository and collaborator with a public example.

#### Scenario: The private-data guard finds no secret
- **WHEN** After `uv sync --frozen` and `mise install --locked`, `mise exec -- tests/test-private-data-scan.sh` and `mise exec -- scripts/private-data-scan.sh dir .` run from the repository root.
- **THEN** Both commands exit with status 0, and the guard prints no finding.
