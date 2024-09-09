terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2"
    }
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3"
    }
    boundary = {
      source  = "hashicorp/boundary"
      version = "~> 1"
    }
  }
}

provider "boundary" {
  addr = var.boundary_address
}

provider "hcp" {
}