# Find the public image to be used for deployment. You can indicate image by either
# image family or image name. By default, the Fortinet's public project and newest
# 72 PAYG image is used.
data "google_compute_image" "fgt_image" {
  project         = var.image_project
  family          = var.image_name == null ? var.image_family : null
  name            = var.image_name
}


# Pull information about subnets we will connect to FortiGate instances. Subnets must
# already exist (can be created in parent module).
data "google_compute_subnetwork" "subnets" {
  count           = length(var.subnets)
  name            = var.subnets[count.index]
  region          = var.region
}

# Pull default zones and the service account. Both can be overridden in variables if needed.
data "google_compute_zones" "zones_in_region" {
  region          = var.region
}

data "google_compute_default_service_account" "default" {
}

locals {
  zones = [
    var.zones[0]  != "" ? var.zones[0] : data.google_compute_zones.zones_in_region.names[0],
    var.zones[1]  != "" ? var.zones[1] : data.google_compute_zones.zones_in_region.names[1]
  ]
}

# We'll use shortened region and zone names for some resource names. This is a standard shortening described in
# GCP security foundations.
locals {
  region_short    = replace( replace( replace( replace(var.region, "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa")
  zones_short     = [
    replace( replace( replace( replace(local.zones[0], "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa"),
    replace( replace( replace( replace(local.zones[1], "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa")
  ]
}

# VPN config
locals {
  fgt_vpn_config = templatefile("${path.module}/fgt_vpns.tftpl", {
    vpn_peers = var.vpn_peers
    vpn_secret = var.vpn_secret
    vpn_hub_ip = var.frontends["vpnhub"]
    })
}

# Create new random API key to be provisioned in FortiGates.
resource "random_string" "api_key" {
  length                 = 30
  special                = false
  numeric                = true
}

# Create FortiGate instances with secondary logdisks and configuration. Everything 2 times (active + passive)
resource "google_compute_disk" "logdisk" {
  count                  = var.cluster_size

  name                   = "${var.prefix}disk-logdisk${count.index+1}-${local.zones_short[count.index]}"
  size                   = var.logdisk_size
  type                   = "pd-ssd"
  zone                   = local.zones[count.index]
}



resource "google_compute_instance" "fgt-vm" {
  count                  = var.cluster_size

  zone                   = local.zones[count.index % length(local.zones)]
  name                   = "${var.prefix}-fgt${count.index+1}-${local.zones_short[count.index]}"
  machine_type           = var.machine_type
  can_ip_forward         = true
  tags                   = ["fgt"]

  boot_disk {
    initialize_params {
      image              = data.google_compute_image.fgt_image.self_link
    }
  }
  attached_disk {
    source               = google_compute_disk.logdisk[count.index].name
  }

  service_account {
    email                = (var.service_account != "" ? var.service_account : data.google_compute_default_service_account.default.email)
    scopes               = ["cloud-platform"]
  }

  metadata = {
//    user-data            = (count.index == 0 ? local.config_active : local.config_passive )
    user-data = templatefile("${path.module}/base-config-flex.tpl", {
        hostname               = "${var.prefix}-fgt${count.index+1}-${local.zones_short[0]}"
        healthcheck_port       = var.healthcheck_port
        api_key                = random_string.api_key.result
        api_acl                = var.api_acl
        fgt_config             = "${local.fgt_vpn_config}\n ${var.fgt_config}"
        flexvm_token           = var.flexvm_tokens[count.index]
        ha_indx                = count.index
        ha_peers               = setsubtract( google_compute_address.fgsp_priv[*].address, [google_compute_address.fgsp_priv[count.index].address])
        port1_ip               = google_compute_address.pub_priv[count.index].address
        port1_subnet           = data.google_compute_subnetwork.subnets[0].ip_cidr_range
        port1_gw               = data.google_compute_subnetwork.subnets[0].gateway_address
        port2_ip               = google_compute_address.fgsp_priv[count.index].address
        port2_subnet           = data.google_compute_subnetwork.subnets[1].ip_cidr_range
        port2_gw               = data.google_compute_subnetwork.subnets[1].gateway_address
        frontends              = [ for eip in var.frontends : eip ]
        hq_subnets             = [ for subnet in var.cidrs_hq : subnet ]
        hq_via                 = data.google_compute_subnetwork.subnets[6].gateway_address
        })
    license              = fileexists(var.license_files[count.index]) ? file(var.license_files[count.index]) : null
    serial-port-enable   = true
  }

  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[0].id
    network_ip           = google_compute_address.pub_priv[count.index].address
    access_config {
      nat_ip             = google_compute_address.mgmt_pub[count.index].address
    }
  }
  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[1].id
    network_ip           = google_compute_address.fgsp_priv[count.index].address
  }
  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[2].id
    network_ip           = google_compute_address.prod_priv[count.index].address
  }
  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[3].id
    network_ip           = google_compute_address.comm_priv[count.index].address
  }
  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[4].id
    network_ip           = google_compute_address.test_priv[count.index].address
  }
  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[5].id
    network_ip           = google_compute_address.dev_priv[count.index].address
  }
  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[6].id
    network_ip           = google_compute_address.trans_priv[count.index].address
  }
} //fgt-vm


# Common Load Balancer resources
resource "google_compute_region_health_check" "health_check" {
  name                   = "${var.prefix}healthcheck-http${var.healthcheck_port}-${local.region_short}"
  region                 = var.region
  timeout_sec            = 2
  check_interval_sec     = 2

  http_health_check {
    port                 = var.healthcheck_port
  }
}

resource "google_compute_instance_group" "fgt-umigs" {
  count                  = length(local.zones)

  name                   = "${var.prefix}umig${count.index}-${local.zones_short[count.index]}"
  zone                   = local.zones[count.index]
  instances = matchkeys(google_compute_instance.fgt-vm[*].self_link, google_compute_instance.fgt-vm[*].zone, [local.zones[count.index]])
//  instances              = [google_compute_instance.fgt-vm[count.index].self_link]
}

# ELB BES
resource "google_compute_region_backend_service" "elb_bes" {
  provider               = google-beta
  name                   = "${var.prefix}bes-elb-${local.region_short}"
  region                 = var.region
  load_balancing_scheme  = "EXTERNAL"
  protocol               = "UNSPECIFIED"

  dynamic "backend" {
    for_each = google_compute_instance_group.fgt-umigs
    content {
      group = backend.value.self_link
    }
  }

  health_checks          = [google_compute_region_health_check.health_check.self_link]
  connection_tracking_policy {
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
  session_affinity = "CLIENT_IP"
}


# Firewall rules
resource "google_compute_firewall" "allow-mgmt" {
  name                   = "${var.prefix}fw-mgmt-allow-admin"
  network                = data.google_compute_subnetwork.subnets[3].network
  source_ranges          = var.admin_acl
  target_tags            = ["fgt"]

  allow {
    protocol             = "all"
  }
}

resource "google_compute_firewall" "allow-hasync" {
  name                   = "${var.prefix}fw-hasync-allow-fgt"
  network                = data.google_compute_subnetwork.subnets[2].network
  source_tags            = ["fgt"]
  target_tags            = ["fgt"]

  allow {
    protocol             = "all"
  }
}

resource "google_compute_firewall" "allow-port1" {
  name                   = "${var.prefix}fw-ext-allowall"
  network                = data.google_compute_subnetwork.subnets[0].network
  source_ranges          = ["0.0.0.0/0"]

  allow {
    protocol             = "all"
  }
}

resource "google_compute_firewall" "allow-port2" {
  name                   = "${var.prefix}fw-int-allowall"
  network                = data.google_compute_subnetwork.subnets[1].network
  source_ranges          = ["0.0.0.0/0"]

  allow {
    protocol             = "all"
  }
}

# Enable outbound connectivity via Cloud NAT
resource "google_compute_router" "nat_router" {
  name                   = "${var.prefix}cr-cloudnat-${local.region_short}"
  region                 = var.region
  network                = data.google_compute_subnetwork.subnets[0].network
}

resource "google_compute_router_nat" "cloud_nat" {
  name                   = "${var.prefix}nat-cloudnat-${local.region_short}"
  router                 = google_compute_router.nat_router.name
  region                 = var.region
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = data.google_compute_subnetwork.subnets[0].self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# ELB Frontends
/*
resource "google_compute_address" "frontends" {
  for_each = toset(var.frontends)

  name = "${var.prefix}eip-${each.value}"
  region = var.region
  address_type = "EXTERNAL"
}

resource "google_compute_forwarding_rule" "frontends" {
  for_each = toset(var.frontends)

  name = "${var.prefix}fr-${each.value}"
  region = var.region
  ip_address = google_compute_address.frontends[each.value].self_link
  ip_protocol = "L3_DEFAULT"
  all_ports = true
  load_balancing_scheme = "EXTERNAL"
  backend_service = google_compute_region_backend_service.elb_bes.self_link
}
*/

# for a map of existing EIPs
resource "google_compute_forwarding_rule" "frontends" {
  for_each = var.frontends

  name = "${var.prefix}fr-${each.key}"
  region = var.region
  ip_address = each.value
  ip_protocol = "L3_DEFAULT"
  all_ports = true
  load_balancing_scheme = "EXTERNAL"
  backend_service = google_compute_region_backend_service.elb_bes.self_link
}

# OPTIONAL

# Save api_key to Secret Manager
resource "google_secret_manager_secret" "api-secret" {
  count                  = var.api_token_secret_name!="" ? 1 : 0
  secret_id              = var.api_token_secret_name

  replication {
    automatic            = true
  }
}

resource "google_secret_manager_secret_version" "api_key" {
  count                  = var.api_token_secret_name!="" ? 1 : 0
  secret                 = google_secret_manager_secret.api-secret[0].id
  secret_data            = random_string.api_key.id
}
