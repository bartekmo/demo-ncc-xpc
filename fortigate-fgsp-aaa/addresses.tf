resource "google_compute_address" "mgmt_pub" {
  count                  = var.cluster_size

  region                 = var.region
  name                   = "${var.prefix}eip${count.index+1}-mgmt-${local.region_short}"
}

resource "google_compute_address" "pub_priv" {
  count                  = var.cluster_size

  name                   = "${var.prefix}ip${count.index+1}-pub-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[0].id
}

resource "google_compute_address" "fgsp_priv" {
  count                  = var.cluster_size

  name                   = "${var.prefix}ip${count.index+1}-fgsp-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[1].id
}

resource "google_compute_address" "prod_priv" {
  count                  = var.cluster_size

  name                   = "${var.prefix}ip${count.index+1}-prod-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[2].id
}

resource "google_compute_address" "comm_priv" {
  count                  = var.cluster_size

  name                   = "${var.prefix}ip${count.index+1}-comm-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[3].id
}

resource "google_compute_address" "test_priv" {
  count                  = var.cluster_size

  name                   = "${var.prefix}ip${count.index+1}-test-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[4].id
}
resource "google_compute_address" "ilb_test" {
  name                   = "${var.prefix}ilb-test-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[4].id
}

resource "google_compute_address" "dev_priv" {
  count                  = var.cluster_size

  name                   = "${var.prefix}ip${count.index+1}-dev-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[5].id
}
resource "google_compute_address" "ilb_dev" {
  name                   = "${var.prefix}ilb-dev-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[5].id
}

resource "google_compute_address" "trans_priv" {
  count                  = var.cluster_size

  name                   = "${var.prefix}ip${count.index+1}-transit-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[6].id
}
resource "google_compute_address" "ilb_trans" {
  name                   = "${var.prefix}ilb-transit-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[6].id
}
