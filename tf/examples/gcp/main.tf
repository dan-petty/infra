# The example of the module tf/modules/gcp-gke: a regional GKE cluster in its own VPC network. CI
# runs tofu init -backend=false and tofu validate in this folder. gcp.tfvars.example holds the
# values of a test. The google provider reads its credentials from the environment of the
# consumer, such as the gcloud application default credentials.
provider "google" {
  project = var.project_id
  region  = var.region
}

module "gcp_gke" {
  source = "../../modules/gcp-gke"

  project_id                      = var.project_id
  region                          = var.region
  cluster_name                    = var.cluster_name
  network_name                    = var.network_name
  subnet_cidr                     = var.subnet_cidr
  pods_cidr                       = var.pods_cidr
  services_cidr                   = var.services_cidr
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  machine_type                    = var.machine_type
  node_count                      = var.node_count
  min_node_count                  = var.min_node_count
  max_node_count                  = var.max_node_count
  deletion_protection             = var.deletion_protection
  labels                          = var.labels
}
