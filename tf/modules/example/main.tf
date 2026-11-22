# The example module: the smallest module that tofu fmt, tflint and tofu validate check. It uses no
# provider, so the checks download nothing.
locals {
  url = "https://${var.domain}/"
}
