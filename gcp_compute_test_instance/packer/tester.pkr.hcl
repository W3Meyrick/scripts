packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Variables — supply via variables.pkrvars.hcl or -var flags
# ──────────────────────────────────────────────────────────────────────────────

variable "project_id" {
  type        = string
  description = "GCP project to build the image in"
}

variable "zone" {
  type        = string
  description = "Zone to run the build instance in"
}

variable "network" {
  type        = string
  description = "VPC network for the build instance"
}

variable "subnetwork" {
  type        = string
  description = "Subnet for the build instance"
}

variable "source_image_family" {
  type        = string
  description = "Source RHEL-based image family from your organisation's image project"
}

variable "source_image_project" {
  type        = string
  description = "GCP project that hosts the source image"
}

variable "image_family" {
  type        = string
  description = "Image family name for the output image"
  default     = "gcp-api-dns-tester"
}

# ──────────────────────────────────────────────────────────────────────────────
# Builder
# ──────────────────────────────────────────────────────────────────────────────

source "googlecompute" "tester" {
  project_id              = var.project_id
  zone                    = var.zone
  network                 = var.network
  subnetwork              = var.subnetwork

  source_image_family     = var.source_image_family
  source_image_project_id = [var.source_image_project]

  machine_type  = "e2-medium"
  disk_size     = 20
  disk_type     = "pd-ssd"

  image_name        = "${var.image_family}-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  image_family      = var.image_family
  image_description = "GCP API and DNS continuous tester — built by Packer"

  # No external IP — use IAP tunnelling for Packer SSH access during the build.
  # The account running Packer needs roles/iap.tunnelResourceAccessor.
  use_iap          = true
  omit_external_ip = true
  use_internal_ip  = true

  ssh_username = "packer"
}

# ──────────────────────────────────────────────────────────────────────────────
# Build
# ──────────────────────────────────────────────────────────────────────────────

build {
  sources = ["source.googlecompute.tester"]

  provisioner "ansible" {
    playbook_file = "../ansible/playbook.yml"
  }
}
