resource "google_compute_address" "vpn_hub" {
  region = var.region
  name = "${var.prefix}-vpn-hub"
}

resource "random_string" "vpn_secret" {
  length                 = 20
  special                = false
  numeric                = true
}

module "fgts" {
  source = "./fortigate-fgsp-aaa"

  prefix = var.prefix
  region = var.region
  subnets = [
    google_compute_subnetwork.pub["pub"].name,
    google_compute_subnetwork.fgsp["fgsp"].name,
    google_compute_subnetwork.prod["prod0"].name,
    google_compute_subnetwork.comm["comm0"].name,
    google_compute_subnetwork.test["test0"].name,
    google_compute_subnetwork.dev["dev0"].name,
    google_compute_subnetwork.transit["trans0"].name
  ]
  frontends = {
    "vpnhub": google_compute_address.vpn_hub.address
  }
  fgt_config = templatefile("fgt_bgp_config.tftpl", {
    asn = var.asns.fgt
    bgp_neighbors = local.bgp_neighbors
  })
//  hq_subnets = [ for subnet in var.cidrs_hq : subnet ]
  cidrs_hq = var.cidrs_hq
  flexvm_tokens = var.flexvm_tokens

  vpn_peers = values(module.branches)[*].eip
  vpn_secret  = random_string.vpn_secret.result

  depends_on = [
    google_compute_subnetwork.pub,
    google_compute_subnetwork.fgsp,
    google_compute_subnetwork.prod,
    google_compute_subnetwork.comm,
    google_compute_subnetwork.test,
    google_compute_subnetwork.dev,
    google_compute_subnetwork.transit
  ]
}


module "branches" {
  source = "./branch"
  for_each = toset([for i in range(1,9) : format("%d", i )])

  region = "europe-west1"
  prefix = "${var.prefix}-branch-${each.key}"
  cidr = "172.18.${each.key}.0/24"
  admin_acl = ["145.224.104.0/25"]
  vpn_peer = google_compute_address.vpn_hub.address
  vpn_secret = random_string.vpn_secret.result
  hub_as = var.asns.fgt
  indx = each.key
  flexvm_token = var.branch_tokens[tonumber(each.key)-1]
}
