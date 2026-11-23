# The module has no resource of its own, so it declares no provider: the modules of main.tf declare
# theirs, and the root module of the consumer pins the provider versions (tf/examples/gcp).
terraform {
  required_version = ">= 1.10.5"
}
