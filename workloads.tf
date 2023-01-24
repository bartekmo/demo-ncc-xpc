resource "google_compute_instance" "srv1" {
  zone = "${var.region}-b"
  name = "${var.prefix}-wrkld-srv1"
  machine_type = "e2-standard-2"
  tags = ["frontend"]
  boot_disk {
    initialize_params {
      image              = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
    }
  }
  network_interface {
    subnetwork           = google_compute_subnetwork.prod["prod1"].self_link
    network_ip           = cidrhost(var.cidrs_prod["prod1"], 10)
  }
}
