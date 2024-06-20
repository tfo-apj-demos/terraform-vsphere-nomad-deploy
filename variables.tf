#--- Boundary connection variables
variable "boundary_address" {
  type = string
}

variable "service_account_authmethod_id" {
  type = string
}

variable "service_account_name" {
  type = string
}

variable "service_account_password" {
  type = string
}

#--- Nomad application variables
variable "cluster_size" {
  description = "The number of nodes in the cluster."
  type = number
  default = 3
}

variable "nomad_license" {
  type = string
}

variable "hostnames" {
  type = list(string)
  default = ["nomad-01","nomad-02","nomad-03"]
}

# variable "nomad_vsphere_user" {
#   description = "Used for auto-join node discovery."
#   type = string
# }

# variable "nomad_vsphere_password" {
#   description = "Used for auto-join node discovery."
#   type = string
# }

# variable "nomad_vsphere_host" {
#   description = "Used for auto-join node discovery."
#   type = string
# }

#--- DNS registration variables
# variable "dns_username" {
#   type = string
# }

# variable "dns_password" {
#   type = string
# }

# variable "dns_realm" {
#   type = string
# }

# variable "dns_server" {
#   type = string
# }

variable "load_balancer_dns_name" {
  type = string
}

variable "TFC_WORKSPACE_ID" {}

variable "vault_address" {
  description = "Vault address for Boundary credential store configuration."
  default = "https://vault.hashicorp.local:8200"
}