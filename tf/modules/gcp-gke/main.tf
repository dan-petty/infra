# A regional GKE cluster in its own VPC network: a thin wrapper of the maintained modules
# terraform-google-modules/network/google and terraform-google-modules/kubernetes-engine/google.
# The wrapper maps the inputs of the devops-cli stub tf/gcp onto the inputs of the two modules
# (README.md, "Inputs").
locals {
  subnet_name         = "${var.cluster_name}-subnet"
  pods_range_name     = "k8s-pod-range"
  services_range_name = "k8s-service-range"
}

module "network" {
  source  = "terraform-google-modules/network/google"
  version = "18.3.1"

  project_id   = var.project_id
  network_name = var.network_name

  subnets = [
    {
      subnet_name   = local.subnet_name
      subnet_ip     = var.subnet_cidr
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    (local.subnet_name) = [
      {
        range_name    = local.pods_range_name
        ip_cidr_range = var.pods_cidr
      },
      {
        range_name    = local.services_range_name
        ip_cidr_range = var.services_cidr
      },
    ]
  }
}

# The module makes the service account of the nodes with the roles of logging and monitoring, and
# turns on Workload Identity (identity_namespace) and the GKE metadata server on the nodes, as in
# the devops-cli stub.
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "47.0.0"

  project_id = var.project_id
  name       = var.cluster_name
  regional   = true
  region     = var.region

  network           = module.network.network_name
  subnetwork        = module.network.subnets_names[0]
  ip_range_pods     = local.pods_range_name
  ip_range_services = local.services_range_name

  deletion_protection      = var.deletion_protection
  remove_default_node_pool = true
  cluster_resource_labels  = var.labels

  # Only these ranges can connect to the API server (Trivy GCP-0061), as the AKS module does for
  # Trivy AZU-0041 (devops-cli#5767).
  master_authorized_networks = [
    for cidr in var.api_server_authorized_ip_ranges : {
      cidr_block   = cidr
      display_name = cidr
    }
  ]

  node_pools = [
    {
      name               = "${var.cluster_name}-node-pool"
      machine_type       = var.machine_type
      autoscaling        = true
      initial_node_count = var.node_count
      min_count          = var.min_node_count
      max_count          = var.max_node_count
      preemptible        = false
      # The GKE metadata server hides the metadata of the node from the Pods (Trivy GCP-0057).
      node_metadata = "GKE_METADATA"
    },
  ]

  node_pools_labels = {
    all = var.labels
  }
}
