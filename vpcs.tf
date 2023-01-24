resource "google_compute_network" "pub" {
  name = "${var.prefix}-vpc-pub"
  auto_create_subnetworks = false
  delete_default_routes_on_create = false
}

resource "google_compute_network" "fgsp" {
  name = "${var.prefix}-vpc-fgsp"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
}

resource "google_compute_network" "prod" {
  name = "${var.prefix}-vpc-prod"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
}

resource "google_compute_network" "comm" {
  name = "${var.prefix}-vpc-comm"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
}

resource "google_compute_network" "test" {
  name = "${var.prefix}-vpc-test"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
}

resource "google_compute_network" "dev" {
  name = "${var.prefix}-vpc-dev"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
}

resource "google_compute_network" "transit" {
  name = "${var.prefix}-vpc-transit"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
}

resource "google_compute_network" "hq" {
  name = "${var.prefix}-vpc-hq"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "pub" {
  for_each = var.cidrs_pub

  network = google_compute_network.pub.self_link
  name = "${var.prefix}-${each.key}-${local.region_short}"
  region = var.region
  ip_cidr_range = each.value
}

resource "google_compute_subnetwork" "fgsp" {
  for_each = var.cidrs_fgsp

  network = google_compute_network.fgsp.self_link
  name = "${var.prefix}-${each.key}-${local.region_short}"
  region = var.region
  ip_cidr_range = each.value
}

resource "google_compute_subnetwork" "prod" {
  for_each = var.cidrs_prod

  network = google_compute_network.prod.self_link
  name = "${var.prefix}-${each.key}-${local.region_short}"
  region = var.region
  ip_cidr_range = each.value
}

resource "google_compute_subnetwork" "comm" {
  for_each = var.cidrs_comm

  network = google_compute_network.comm.self_link
  name = "${var.prefix}-${each.key}-${local.region_short}"
  region = var.region
  ip_cidr_range = each.value
}

resource "google_compute_subnetwork" "test" {
  for_each = var.cidrs_test

  network = google_compute_network.test.self_link
  name = "${var.prefix}-${each.key}-${local.region_short}"
  region = var.region
  ip_cidr_range = each.value
}

resource "google_compute_subnetwork" "dev" {
  for_each = var.cidrs_dev

  network = google_compute_network.dev.self_link
  name = "${var.prefix}-${each.key}-${local.region_short}"
  region = var.region
  ip_cidr_range = each.value
}

resource "google_compute_subnetwork" "transit" {
  for_each = var.cidrs_transit

  network = google_compute_network.transit.self_link
  name = "${var.prefix}-${each.key}-${local.region_short}"
  region = var.region
  ip_cidr_range = each.value
}

resource "google_compute_subnetwork" "hq" {
  for_each = var.cidrs_hq

  network = google_compute_network.hq.self_link
  name = "${var.prefix}-${each.key}-${local.region_short}"
  region = var.region
  ip_cidr_range = each.value
}

resource "google_compute_firewall" "prod_allowall" {
  name = "${var.prefix}-fw-prod-allowall"
  network = google_compute_network.prod.self_link
  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "comm_allowall" {
  name = "${var.prefix}-fw-comm-allowall"
  network = google_compute_network.comm.self_link
  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
}
