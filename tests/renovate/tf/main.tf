# A fixture of tests/test-renovate-presets.sh: a consumer pins an OpenTofu module of infra at a
# release tag. The terraform manager of Renovate must read the pin. Nothing runs tofu init here.
module "example" {
  source = "git::https://github.com/dan-petty/infra.git//tf/modules/example?ref=v0.1.0"

  domain = "example.com"
}
