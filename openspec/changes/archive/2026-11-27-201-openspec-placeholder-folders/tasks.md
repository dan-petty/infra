# Tasks

## 1. The OpenSpec folders of the template

Kind: behavior.

- [x] 1.1 Add the two paths to the file list of each render in `tests/test-repository-template.sh`, and a case that both rendered files are empty. See the cases fail on `main`
  - Verification: `$ mise exec -- tests/test-repository-template.sh` exits 1 with 125 of 137 cases passed
- [x] 1.2 Add `templates/repository/openspec/specs/.gitkeep` and `templates/repository/openspec/changes/archive/.gitkeep`, empty
  - Verification: `$ mise exec -- tests/test-repository-template.sh` exits 0 with 137 of 137 cases passed

## 2. Documents

Kind: docs.

- [x] 2.1 Name the two files and the test case in `templates/README.md`
  - Verification: `$ git grep -n gitkeep templates/README.md` shows the file row and the test line
