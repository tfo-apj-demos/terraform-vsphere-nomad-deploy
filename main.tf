locals {
  hostnames = [ for v in range(var.cluster_size): format("nomad-%s", v)]
}

# --- Get latest Nomad image value from HCP Packer
data "hcp_packer_artifact" "this" {
  bucket_name  = "nomad-ubuntu-2204"
  channel_name = "latest"
  platform     = "vsphere"
  region       = "Datacenter"
}

# --- Retrieve IPs for use by the load balancer and Nomad virtual machines
data "nsxt_policy_ip_pool" "this" {
  display_name = "10 - gcve-foundations"
}
resource "nsxt_policy_ip_address_allocation" "this" {
  for_each = toset(var.hostnames)
  display_name = each.value
  pool_path    = data.nsxt_policy_ip_pool.this.path
}

resource "nsxt_policy_ip_address_allocation" "load_balancer" {
  display_name = "nomad-load-balancer"
  pool_path    = data.nsxt_policy_ip_pool.this.path
}

# --- Generate a Vault token for the agent to bootstrap and retrieve certificates
resource "vault_token" "this" {
  for_each = toset(var.hostnames)
  no_parent = true
  period    = "2h"
  policies = [
    "generate_certificate"
  ]
}

# --- Deploy Load Balancer
module "load_balancer" {
  source  = "app.terraform.io/tfo-apj-demos/load-balancer/nsxt"
  version = "0.0.3-beta"

  hosts = [ for host in module.nomad_server : {
    "hostname" = host.virtual_machine_name
    "address"  = host.ip_address
  }]
  ports = [
    "4646"
  ]
  load_balancer_ip_address = nsxt_policy_ip_address_allocation.load_balancer.allocation_ip
  name = "nomad"
  lb_app_profile_type = "TCP"
}

# --- Deploy a cluster of Nomad servers
module "nomad_server" {
  for_each = toset(var.hostnames)
  source  = "app.terraform.io/tfo-apj-demos/virtual-machine/vsphere"
  version = "~> 1.3"

  hostname          = each.value
  datacenter        = "Datacenter"
  cluster           = "cluster"
  primary_datastore = "vsanDatastore"
  folder_path       = "Demo Workloads"
  networks = {
    "seg-general" : "${nsxt_policy_ip_address_allocation.this[each.value].allocation_ip}/22"
  }
  dns_server_list = [
    "172.21.15.150",
    "10.10.0.8"
  ]
  gateway         = "172.21.12.1"
  dns_suffix_list = ["hashicorp.local"]


  template = "nomad-ubuntu-2204-20240317111540" #data.hcp_packer_artifact.this.external_identifier
  tags = {
    "application" = "nomad-server"
  }

  # userdata = templatefile("${path.module}/templates/userdata.yaml.tmpl", {
  #   hostname               = "nomad-server-${each.value}"
  #   vault_address          = var.vault_address
  #   vault_token            = vault_token.this[count.index].client_token
  #   vault_license          = var.vault_license
  #   vault_vsphere_host     = var.vault_vsphere_host
  #   vault_vsphere_user     = var.vault_vsphere_user
  #   vault_vsphere_password = var.vault_vsphere_password
  #   vault_agent_config = base64encode(templatefile("${path.module}/templates/vault_agent.conf.tmpl", {
  #     hostname      = "vault-blue-${count.index + 1}"
  #     vault_address = var.vault_address
  #     private_ip = nsxt_policy_ip_address_allocation.this[count.index].allocation_ip
  #     load_balancer_ip = nsxt_policy_ip_address_allocation.load_balancer.allocation_ip
  #     load_balancer_dns_name = var.load_balancer_dns_name
  #   }))
  #   ip_address = nsxt_policy_ip_address_allocation.this[count.index].allocation_ip
  # })
}

# --- Create Boundary targets for the Vault nodes

# module "boundary_target" {
#   source  = "app.terraform.io/tfo-apj-demos/target/boundary"
#   version = "1.0.11-alpha"

#   hosts = [ for host in module.nomad_server : {
#     "hostname" = host.virtual_machine_name
#     "address"  = host.ip_address
#   }]

#   services = [
#     {
#       name             = "rdp",
#       type             = "ssh",
#       port             = "22"
#     }
#   ]

#   project_name           = "shared_services"
#   host_catalog_id        = "hcst_1lWZVwU02l"
#   hostname_prefix        = "remote_desktop"
#   #credential_store_token = vault_token.this.client_token
#   #vault_address          = var.vault_address
#   #vault_ca_cert          = file("${path.root}/ca_cert_dir/ca_chain.pem")
# }


# --- Add LB to DNS
module "load_balancer_dns" {
  source  = "app.terraform.io/tfo-apj-demos/domain-name-system-management/dns"
  version = "~> 1.0"

  a_records = [
    {
      name      = var.load_balancer_dns_name
      addresses = [nsxt_policy_ip_address_allocation.load_balancer.allocation_ip]
    }
  ]
}

# --- Add servers to DNS
module "nomad_server_dns" {
  source  = "app.terraform.io/tfo-apj-demos/domain-name-system-management/dns"
  version = "~> 1.0"

  a_records = [ for host in module.nomad_server : {
    "name" = host.virtual_machine_name
    "addresses"  = [ host.ip_address ]
  }]
}
