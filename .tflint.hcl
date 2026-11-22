# tflint settings of the OpenTofu job of CI: all rules of the terraform ruleset, which tflint
# bundles, so `tflint --init` downloads no plugin. CI runs
# `tflint --recursive --config "$PWD/.tflint.hcl"` from the repository root.
plugin "terraform" {
  enabled = true
  preset  = "all"
}
