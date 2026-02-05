# Provider Scaleway (credentials et project configurés à l'extérieur)
provider "scaleway" {
  access_key = var.scw_access_key
  secret_key = var.scw_secret_key
  project_id = var.scw_project_id
  region     = var.region
}

terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.28.0"
    }
  }
}

# 1. VPC et Private Network
resource "scaleway_vpc" "vpc" {
  name = "workshop-vpc"
}
resource "scaleway_vpc_private_network" "pn" {
  name   = "workshop-pn"
  vpc_id = scaleway_vpc.vpc.id
  ipv4_subnet {
    subnet = "172.16.64.0/22"
  }
}
resource "scaleway_ipam_ip" "pgw" {
  address = "172.16.64.7"
  source {
    private_network_id = scaleway_vpc_private_network.pn.id
  }
}

resource "scaleway_vpc_public_gateway" "pgw" {
  name            = "workshop-pgw"
  type            = "VPC-GW-S"
  bastion_enabled = true
  bastion_port    = 61000
}

resource "scaleway_vpc_gateway_network" "pgw" {
  gateway_id         = scaleway_vpc_public_gateway.pgw.id
  private_network_id = scaleway_vpc_private_network.pn.id
  enable_masquerade  = true
  ipam_config {
    push_default_route = true
    ipam_ip_id         = scaleway_ipam_ip.pgw.id
  }
}

# 2. Cluster Kapsule + Node Pool
resource "scaleway_k8s_cluster" "workshop" {
  name                        = "cluster-workshop"
  type                        = "kapsule"
  region                      = var.region
  version                     = "1.32.3"
  cni                         = "cilium"
  private_network_id          = scaleway_vpc_private_network.pn.id
  delete_additional_resources = true
  depends_on = [scaleway_ipam_ip.pgw]
}


resource "scaleway_k8s_pool" "workshop" {
  name                   = "pool-workshop"
  zone                   = "fr-par-2"
  cluster_id             = scaleway_k8s_cluster.workshop.id
  public_ip_disabled     = true
  node_type              = "POP2-2C-8G"
  size                   = 4
  autoscaling            = false
  autohealing            = true
  container_runtime      = "containerd"
  root_volume_size_in_gb = 32

  depends_on = [scaleway_ipam_ip.pgw]
}


# 3. S2S VPN Scaleway

resource "scaleway_s2s_vpn_gateway" "vgw" {
  name               = "workshop-vpn-gw"
  private_network_id = scaleway_vpc_private_network.pn.id
  gateway_type       = "VGW-S"
}

# Customer Gateway côté Scaleway (représente AWS)
resource "scaleway_s2s_vpn_customer_gateway" "cgw" {
  name        = "aws-customer-gw"
  ipv4_public = aws_vpn_connection.to_scaleway.tunnel1_address # IP du tunnel côté AWS
  asn         = var.cgw_asn # ASN BGP côté AWS (fourni par AWS)
}

# Politique de routage (à adapter selon vos besoins)
resource "scaleway_s2s_vpn_routing_policy" "policy" {
  name    = "workshop-vpn-policy"
  is_ipv6 = false
  prefix_filter_in  = var.aws_plage
  prefix_filter_out = [scaleway_vpc_private_network.pn.ipv4_subnet[0].subnet]
}

# Connexion VPN S2S
resource "scaleway_s2s_vpn_connection" "main" {
  name                     = "workshop-connection"
  vpn_gateway_id           = scaleway_s2s_vpn_gateway.vgw.id
  customer_gateway_id      = scaleway_s2s_vpn_customer_gateway.cgw.id
  initiation_policy        = "customer_gateway"
  enable_route_propagation = true

  bgp_config_ipv4 {
    routing_policy_id = scaleway_s2s_vpn_routing_policy.policy.id
    private_ip        = "169.254.0.1/30"   # IP côté Scaleway (adapter si besoin)
    peer_private_ip   = "169.254.0.2/30"   # IP côté AWS (adapter si besoin)
  }

  ikev2_ciphers {
    encryption = "aes256"
    integrity  = "sha256"
    dh_group   = "modp2048"
  }

  esp_ciphers {
    encryption = "aes256"
    integrity  = "sha256"
    dh_group   = "modp2048"
  }
}


# data "scaleway_secret_version" "s2s_psk" {
#   secret_id = scaleway_s2s_vpn_connection.main.secret_id
#   revision  = tostring(scaleway_s2s_vpn_connection.main.secret_version)
# }

# output "psk" {
#   value     = data.scaleway_secret_version.s2s_psk.data
#   sensitive = true
# }


#4. Object Storage
resource "scaleway_object_bucket" "workshop" {
  name   = "workshop-bucket-010101"
  region = var.region
  versioning {
    enabled = true
  }
}

# #5. MongoDB
resource "scaleway_mongodb_instance" "workshop" {
  name              = "workshop-mongo"
  version           = "7.0"
  node_type         = "MGDB-PRO2-XS"
  node_number       = 1
  user_name         = "admin"
  password          = "Workshop_2026!"
  volume_size_in_gb = 5

  private_network {
    pn_id = scaleway_vpc_private_network.pn.id
  }

}
# ...existing code...

# Récupérer l'IPAM config ID de la gateway VPN
data "scaleway_ipam_ip" "vpn_gw_public_ip" {
  ipam_ip_id = scaleway_s2s_vpn_gateway.vgw.public_config[0].ipam_ipv4_id
}

output "vpn_gateway_public_ip" {
  value = data.scaleway_ipam_ip.vpn_gw_public_ip.address
}