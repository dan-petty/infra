# infra — AI Agent Instructions

infra holds the shared infrastructure templates and their checks. It serves two or more consumers of a template or a platform stack.

This file is the single source of truth for AI agent instructions. [CLAUDE.md](./CLAUDE.md), [GEMINI.md](./GEMINI.md) and [.github/copilot-instructions.md](./.github/copilot-instructions.md) are thin pointers to this file.

## Rules for every task

1. Branch from `main` and open a pull request for every change.
2. Write the test before the code.
3. Before you push, run the command of each CI job whose files your change touches (README.md, "Checks").
4. Keep secrets and private data out of the repository.
5. Use `<domain>`, `example.com`, and the RFC 5737 addresses in all templates.
6. Pin consumers at a release tag `vX.Y.Z`, never at `main`.
7. Install the tools with `mise install --locked` and `uv sync --frozen` (README.md, "Tools").
8. Run `uv lock` after a version change in `pyproject.toml`.
9. Place each template in the folder that the layout table names.
10. Keep the `example` fixture of each folder passing.
11. Keep the private-data guard passing: no real domain, host, address, or token.

## Where to look

| When you | Read |
| --- | --- |
| Start a task or look up a rule | [README.md](./README.md) |
| Add a template or a check | [README.md](./README.md) |
| Pin a release or call a workflow | [README.md](./README.md) |
