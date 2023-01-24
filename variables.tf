variable "prefix" {
  type = string
  description = "Prefix for all created resources"
  default = "bm-bit"
}

variable "region" {
  type = string
  default = "europe-west2"
}

variable "asns" {
  type = map(string)
  default = {
    fgt = 65100,
    prod = 65000,
    comm = 65001
  }
}

variable "cidrs_pub" {
  type = map(string)
  description = "name to cidr map of pub subnets"
}
variable "cidrs_fgsp" {
  type = map(string)
  description = "name to cidr map of fgsp subnets"
}
variable "cidrs_prod" {
  type = map(string)
  description = "name to cidr map of prod subnets"
}
variable "cidrs_comm" {
  type = map(string)
  description = "name to cidr map of comm subnets"
}
variable "cidrs_test" {
  type = map(string)
  description = "name to cidr map of test subnets"
}
variable "cidrs_dev" {
  type = map(string)
  description = "name to cidr map of dev subnets"
}
variable "cidrs_transit" {
  type = map(string)
  description = "name to cidr map of transit network subnets"
}
variable "cidrs_hq" {
  type = map(string)
  description = "name to cidr map of emulated hq subnets"
}

variable "connected_subnets" {
  type = list(string)
  description = "ordered list of subnets fgt connects to"
}

variable "flexvm_tokens" {
  type = list(string)
  description = "List of FlexVM tokens to license hub FGTs"
}

variable "branch_tokens" {
  type = list(string)
  description = "FlexVM tokens for branches"
}
# Pull and calculated local variables
data "google_compute_zones" "zones_in_region" {
  region          = var.region
}

data "google_compute_default_service_account" "default" {
}

locals {
  zones = [
    data.google_compute_zones.zones_in_region.names[0],
    data.google_compute_zones.zones_in_region.names[1]
  ]
}

# We'll use shortened region and zone names for some resource names. This is a standard shortening described in
# GCP security foundations.
locals {
  region_short    = replace( replace( replace( replace( replace( replace( var.region, "north", "n" ), "west", "w"), "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa")
  zones_short     = [
    replace( replace( replace( replace(replace(local.zones[0], "west", "w"), "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa"),
    replace( replace( replace( replace(replace(local.zones[1], "west", "w"), "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa")
  ]
}
