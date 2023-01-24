resource "google_network_connectivity_hub" "hub" {
  name = "${var.prefix}-ncc-hub"
}

resource "google_network_connectivity_spoke" "prod" {
  hub = google_network_connectivity_hub.hub.id
  name = "${var.prefix}-spoke-prod"
  location = var.region
  linked_router_appliance_instances {
    site_to_site_data_transfer = false
    instances {
      virtual_machine = module.fgts.fgt_self_links[0]
      ip_address = module.fgts.prod_ips[0]
    }
    instances {
      virtual_machine = module.fgts.fgt_self_links[1]
      ip_address = module.fgts.prod_ips[1]
    }
  }
}

resource "google_compute_router" "prod" {
  name = "${var.prefix}-cr-prod"
  network = google_compute_network.prod.name
  bgp {
    asn = var.asns.prod
  }
}

resource "google_compute_address" "cr_prod" {
  count = 2

  name                   = "${var.prefix}-ip-crnic-prod${count.index}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = google_compute_subnetwork.prod[var.connected_subnets[2]].id
}
resource "google_compute_router_interface" "prod0" {
  name = "crnic0"
  router = google_compute_router.prod.name
  region = var.region
  subnetwork = google_compute_subnetwork.prod[var.connected_subnets[2]].id
  private_ip_address = google_compute_address.cr_prod[0].address
}
resource "google_compute_router_interface" "prod1" {
  name = "crnic1"
  router = google_compute_router.prod.name
  region = var.region
  subnetwork = google_compute_subnetwork.prod[var.connected_subnets[2]].id
  private_ip_address = google_compute_address.cr_prod[1].address
  redundant_interface = google_compute_router_interface.prod0.name
}

resource "google_compute_router_peer" "prod" {
  for_each = {
    for x in setproduct(["crnic0","crnic1"], [0, 1]) : "${x[0]}-fgt${x[1]}" => {
      crnic = x[0]
      fgt_indx = x[1]
    }
  }
  name = each.key
  router = google_compute_router.prod.name
  region = var.region
  peer_asn = var.asns.fgt
  peer_ip_address = module.fgts.prod_ips[each.value.fgt_indx]
  router_appliance_instance = module.fgts.fgt_self_links[each.value.fgt_indx]
  interface = each.value.crnic

  depends_on = [
    google_compute_router_interface.prod0,
    google_compute_router_interface.prod1
  ]
}


###### Comm spoke

resource "google_network_connectivity_spoke" "comm" {
  hub = google_network_connectivity_hub.hub.id
  name = "${var.prefix}-spoke-comm"
  location = var.region
  linked_router_appliance_instances {
    site_to_site_data_transfer = false
    instances {
      virtual_machine = module.fgts.fgt_self_links[0]
      ip_address = module.fgts.comm_ips[0]
    }
    instances {
      virtual_machine = module.fgts.fgt_self_links[1]
      ip_address = module.fgts.comm_ips[1]
    }
  }
}

resource "google_compute_router" "comm" {
  name = "${var.prefix}-cr-comm"
  network = google_compute_network.comm.name
  bgp {
    asn = var.asns.comm
  }
}

resource "google_compute_address" "cr_comm" {
  count = 2

  name                   = "${var.prefix}-ip-crnic-comm${count.index}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = google_compute_subnetwork.comm[var.connected_subnets[3]].id
}
resource "google_compute_router_interface" "comm0" {
  name = "crnic0"
  router = google_compute_router.comm.name
  region = var.region
  subnetwork = google_compute_subnetwork.comm[var.connected_subnets[3]].id
  private_ip_address = google_compute_address.cr_comm[0].address
}
resource "google_compute_router_interface" "comm1" {
  name = "crnic1"
  router = google_compute_router.comm.name
  region = var.region
  subnetwork = google_compute_subnetwork.comm[var.connected_subnets[3]].id
  private_ip_address = google_compute_address.cr_comm[1].address
  redundant_interface = google_compute_router_interface.comm0.name
}

resource "google_compute_router_peer" "comm" {
  for_each = {
    for x in setproduct(["crnic0","crnic1"], [0, 1]) : "${x[0]}-fgt${x[1]}" => {
      crnic = x[0]
      fgt_indx = x[1]
    }
  }
  name = each.key
  router = google_compute_router.comm.name
  region = var.region
  peer_asn = var.asns.fgt
  peer_ip_address = module.fgts.comm_ips[each.value.fgt_indx]
  router_appliance_instance = module.fgts.fgt_self_links[each.value.fgt_indx]
  interface = each.value.crnic

  depends_on = [
    google_compute_router_interface.comm0,
    google_compute_router_interface.comm1
  ]
}

locals {
  bgp_neighbors = [
    {
      asn = var.asns.prod
      ip  = google_compute_address.cr_prod[0].address
    },
    {
      asn = var.asns.prod
      ip  = google_compute_address.cr_prod[1].address
    },
    {
      asn = var.asns.comm
      ip  = google_compute_address.cr_comm[0].address
    },
    {
      asn = var.asns.comm
      ip  = google_compute_address.cr_comm[1].address
    },
  ]
}
