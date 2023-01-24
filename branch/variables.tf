variable "prefix" {
  type = string
  description = "Prepended to all resource names"
}
variable "cidr" {
  type = string
  description = "IP space assigned to this branch"
}
variable "vpn_peer" {
  type = string
  description = "IP address of VPN endpoint to connect to"
}
variable "region" {
  type = string
}
variable "admin_acl" {
  type = list(string)
  description = "ACL for FGT management cloud firewall rule"
  default = ["0.0.0.0/0"]
}
variable "vpn_secret" {
  type = string
  description = "Secret to use for ipsec phase1"
}
variable "hub_as" {
  type = string
  description = "ASN for the VPN hub gates"
}
variable "indx" {
  type = string
  description = "Branch index value used to easily generate many identical instances. Used in names, ASNs, CIDRs"
}
variable "flexvm_token" {
  type = string
}
