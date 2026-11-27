# Design

## Decisions

- **Name the Pages site as a `pages` object with the fields `build_type`, `source`, `cname` and `https_enforced`.**: The object names each field of the Pages request body, and `additionalProperties: false` refuses a misspelled field, as the rest of `templates/github-repository.schema.json` does.
- **Name the collaborators as an array of objects with a required `username` and a required `permission` of `pull`, `triage`, `push`, `maintain` or `admin`.**: An array validates each item and keeps the order of the answer, and the enum is the set of permissions of the collaborator endpoint of the GitHub REST API.
- **Ask for the site with a `pages` answer that defaults to false, and render `pages: { build_type: workflow }`.**: Not every repository publishes a site, so a default render holds no `pages` key, and the build type `workflow` publishes the site from a workflow of the repository.
- **Ask for the collaborators as a comma-separated `username:permission` answer with default empty, and validate each pair in `copier.yml`.**: Copier refuses a pair with an unknown permission before the render, so no invalid collaborator reaches the settings baseline, and the empty default adds no collaborator.
- **Render the environment `github-pages` with `protected_branches: false`, `custom_branch_policies: true` and the branch policy `main`, and render `environments` when `release_flow` or `pages` is true.**: Only `main` deploys the site, and a repository with no release flow and no site keeps no `environments` key, which the case at `tests/test-repository-template.sh:140:expect "defaults: no environment" "0" \` asserts.
- **Keep the exact Pages and collaborator values of dan-petty/devops-cli in its own `.copier-answers.yml`, and leave that render to #188.**: The values are the answers of one repository, and `scripts/private-data-scan.sh` refuses a private value in this repository.

## Rejected alternatives

- **A boolean `pages` key.**: It cannot name the build type or the source, and `templates/github-repository.schema.json` holds an object for each endpoint, such as `code_scanning_default_setup`, so a boolean breaks the shape of the file.
- **A free-form object for `pages`.**: `templates/github-repository.schema.json` sets `additionalProperties: false` on each object, so a misspelled `buildtype` fails; a free-form object would accept it.
- **A map of username to permission for the collaborators.**: A JSON Schema map cannot require a permission for each key or name the item that fails; the array of objects gives the failing index, and the validator of `copier.yml` refuses the answer before the render.
- **A hardcoded Pages site or collaborator in the template.**: `scripts/private-data-scan.sh` and `tests/test-private-data-scan.sh` refuse a private value in the repository, and one hardcoded value would give every render the settings of one repository.
- **The `protected_branches` policy of the environment, or no policy at all.**: `templates/github-repository.schema.json` holds both `protected_branches` and `custom_branch_policies`; the protected policy admits each protected branch and no policy admits any branch, while the custom policy names `main` alone.
