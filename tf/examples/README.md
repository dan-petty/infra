# OpenTofu examples

Each folder `tf/examples/<module>/` calls one module of `tf/modules/` with the values of a test:
`example.com` and RFC 5737 addresses. An example has no backend and no state.

The OpenTofu job of CI runs `tofu init -backend=false` and `tofu validate` in each example, and
`tofu fmt -check` and tflint on it (README.md, "Checks"). No consumer uses an example.
