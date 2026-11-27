## Purpose
The settings baseline schema and the Copier template of a new repository: the Pages site, the collaborators and the environment that publishes the site.

## ADDED Requirements

### Requirement: The settings schema names a Pages site
The repository settings schema SHALL name a `pages` object with a required `build_type` of `legacy` or `workflow`, an optional `source` of `branch` and `path`, and the optional `cname` and `https_enforced` fields, and SHALL refuse each field that it does not name.

#### Scenario: The rendered Pages site passes the schema
- **WHEN** `uv run devops ci --check --only template` renders `templates/repository/github/repository.yaml.jinja` with the answer `pages=true`.
- **THEN** The run prints `ok pages: github/repository.yaml matches its schema` and exits with status 0.

### Requirement: The settings schema names the collaborators
The repository settings schema SHALL name a `collaborators` array whose items hold a required `username` and a required `permission` of `pull`, `triage`, `push`, `maintain` or `admin`, and SHALL refuse each field of an item that it does not name.

#### Scenario: The rendered collaborator passes the schema
- **WHEN** `uv run devops ci --check --only template` renders `templates/repository/github/repository.yaml.jinja` with the answer `collaborators=example-user:push`.
- **THEN** The run prints `ok pages: github/repository.yaml matches its schema` and exits with status 0.

### Requirement: The pages answer renders the site and its environment
The template SHALL render the `pages` key with `build_type: workflow` and the environment `github-pages` with the branch policy `main` when the `pages` answer is true.

#### Scenario: The pages answer renders the site and the environment
- **WHEN** `uv run devops ci --check --only template` renders `templates/repository/github/repository.yaml.jinja` with the answer `pages=true`.
- **THEN** The run prints `ok pages: build type` and `ok pages: github-pages environment`.

### Requirement: The collaborators answer renders each collaborator
The template SHALL render each `username:permission` pair of the `collaborators` answer as an item of `collaborators` with the `username` and the `permission` of the pair.

#### Scenario: A collaborator answer renders one collaborator
- **WHEN** `uv run devops ci --check --only template` renders `templates/repository/github/repository.yaml.jinja` with the answer `collaborators=example-user:push`.
- **THEN** The run prints `ok pages: collaborator`.

### Requirement: Copier refuses an invalid collaborator answer
Copier MUST refuse a `collaborators` answer that is not a `username:permission` pair with a permission of `pull`, `triage`, `push`, `maintain` or `admin`.

#### Scenario: Copier refuses an unknown permission
- **WHEN** `uv run devops ci --check --only template` runs the refusal case of `tests/test-repository-template.sh` with the answer `collaborators=example-user:owner`.
- **THEN** The run prints `ok copier refuses collaborators=example-user:owner`.

### Requirement: The template holds no private value
The template, its schema and its test SHALL hold no secret value and SHALL name each example repository and collaborator with a public example.

#### Scenario: The private-data guard finds no secret
- **WHEN** `uv run devops ci --check --only private-data` runs `tests/test-private-data-scan.sh` and the guard on the repository.
- **THEN** The command exits with status 0 and prints no finding.
