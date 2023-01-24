terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "google" {
  project = "forti-emea-se"
  region  = var.region
}
provider "google-beta" {
  project = "forti-emea-se"
  region  = var.region
}
