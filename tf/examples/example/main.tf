# The example of the module tf/modules/example, with the values of a test. CI runs tofu init
# -backend=false and tofu validate in this folder.
module "example" {
  source = "../../modules/example"

  domain = "example.com"
}
