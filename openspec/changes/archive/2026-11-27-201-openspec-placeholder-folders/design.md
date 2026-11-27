# Design: the template keeps the OpenSpec folders

## Decisions
- **Ship the two placeholder files of `openspec init`.** The template holds `openspec/config.yaml` as a static file. The two empty `.gitkeep` files give the same layout as `openspec init`, with no render-time tool.
- **Test the exact file list and the size.** `tests/test-repository-template.sh` already compares the exact file list of each render; the two paths join the list of each answer set, and `validate` checks that both files are empty. The update and recopy cases of the test cover the files too: the next tag writes no line into an empty file, so both stay equal to the render of the next tag.

## Rejected alternatives
- **`openspec validate --specs --strict` in the rendered folder** (the third acceptance point of #201). OpenSpec 2.2.0 prints "No items found to validate." and exits 0 with the folders and also without them, so the command proves nothing about the layout. It also needs OpenSpec in the tools of infra.
- **A Copier task that runs `openspec init`.** It asks questions and writes tool skills, and each render then depends on the tool.
- **Change the onboard row of devops-cli to accept a missing `openspec/specs/`.** `openspec init` writes the folder, so the template follows the tool. The message of the row stays true once a release of the template holds the folder.
