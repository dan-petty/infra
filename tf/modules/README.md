# OpenTofu modules

Each folder `tf/modules/<module>/` is one OpenTofu module. A module holds no value of one
environment and no state: the consumer gives each value as a variable. Each module has an example
in `tf/examples/<module>/`.

The OpenTofu job of CI runs `tofu fmt -check` and tflint (`.tflint.hcl`, all rules of the
terraform ruleset) on each module (README.md, "Checks").

The README of each module names its consumers.

| Module | Content | Consumers |
| --- | --- | --- |
| `example` | One output from one variable: the fixture of the checks. | None. |

A consumer pins a module at a release tag of infra:

```hcl
module "<name>" {
  source = "git::https://github.com/dan-petty/infra.git//tf/modules/<module>?ref=vX.Y.Z"
}
```
