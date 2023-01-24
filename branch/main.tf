data "google_compute_zones" "zones_in_region" {
  region          = var.region
}

data "google_compute_default_service_account" "default" {
}

locals {
  subnets = cidrsubnets( var.cidr, 1, 1)
  fgt_image = "https://www.googleapis.com/compute/v1/projects/fortigcp-project-001/global/images/fortinet-fgt-723-20221110-001-w-license"
  fgt_config = templatefile("${path.module}/fgt_config.tftpl", {
    name          = "${var.prefix}-fgt"
    gw            = google_compute_subnetwork.fw.gateway_address
    wrkld_cidr    = google_compute_subnetwork.wrkld.ip_cidr_range
    vpn_hub_ip    = var.vpn_peer
    vpn_secret    = var.vpn_secret
    bgp_local169  = "169.254.${var.indx}.2"
    bgp_remote169 = "169.254.${var.indx}.1"
    bgp_as        = 65100 + var.indx
    bgp_hub_as    = var.hub_as
    flexvm_token  = var.flexvm_token
    })
}

resource "google_compute_network" "branch" {
  name = "${var.prefix}-vpc-pub"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
}
resource "google_compute_subnetwork" "fw" {
  network = google_compute_network.branch.self_link
  name = "${var.prefix}-fw"
  region = var.region
  ip_cidr_range = local.subnets[0]
}
resource "google_compute_subnetwork" "wrkld" {
  network = google_compute_network.branch.self_link
  name = "${var.prefix}-wrkld"
  region = var.region
  ip_cidr_range = local.subnets[1]
}

resource "google_compute_address" "fgt_eip" {
  region = var.region
  name   = "${var.prefix}-fgteip"
}

resource "google_compute_instance" "fgt" {
  zone                   = data.google_compute_zones.zones_in_region.names[0]
  name                   = "${var.prefix}-fgt"
  machine_type           = "e2-standard-2"
  can_ip_forward         = true
  tags                   = ["fgt"]
//  provisioning_model     = "SPOT"

  boot_disk {
    initialize_params {
      image              = local.fgt_image
    }
  }

  service_account {
    email                = data.google_compute_default_service_account.default.email
    scopes               = ["cloud-platform"]
  }

  network_interface {
    subnetwork           = google_compute_subnetwork.fw.self_link
    access_config {
      nat_ip             = google_compute_address.fgt_eip.address
    }
  }

  metadata = {
    user-data = local.fgt_config
  }
}

resource "google_compute_instance" "client" {
  zone = data.google_compute_zones.zones_in_region.names[0]
  name = "${var.prefix}-vm1"
  machine_type = "e2-standard-2"
  tags = ["secured"]
  boot_disk {
    initialize_params {
      image              = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
    }
  }
  network_interface {
    subnetwork           = google_compute_subnetwork.wrkld.self_link
  }

  scheduling {
    provisioning_model = "SPOT"
    preemptible = true
    automatic_restart = false
  }
}

resource "google_compute_route" "secure_via_fgt" {
  name = "${var.prefix}-secured-via-fgt"
  dest_range = "0.0.0.0/0"
  network = google_compute_network.branch.self_link
  next_hop_instance = google_compute_instance.fgt.self_link
  tags = ["secured"]
}

resource "google_compute_route" "fgt_direct" {
  name = "${var.prefix}-fgt-direct"
  dest_range = "0.0.0.0/0"
  network = google_compute_network.branch.self_link
  next_hop_gateway = "default-internet-gateway"
  tags = ["fgt"]
}

resource "google_compute_firewall" "fgt_admin" {
  name = "${var.prefix}-fgt-allow-admin"
  network = google_compute_network.branch.self_link
  source_ranges = var.admin_acl
  target_tags = ["fgt"]
  allow {
    protocol = "tcp"
    ports = ["22", "443"]
  }
}
resource "google_compute_firewall" "secure_allowall" {
  name = "${var.prefix}-secure-allowall"
  network = google_compute_network.branch.self_link
  source_ranges =[ "0.0.0.0/0"]
  target_tags = ["secured"]
  allow {
    protocol = "all"
  }
}
