provider "aws" {
  region = "eu-west-3" # Paris
}

# --- NETWORK ---
resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "aws-vpc-hybrid" }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "eu-west-3a"
  tags = { Name = "aws-subnet-public" }
}

# second subnet in another AZ for resolver/high-availability
resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "eu-west-3b"
  tags = { Name = "aws-subnet-public-b" }
}

# --- VPN & CONNECTIVITY ---
# L'IP ici doit être celle de ta Flexible IP Scaleway rattachée à ta VPN GW
resource "aws_customer_gateway" "scw_side" {
  bgp_asn    = 65000
  ip_address = var.scw_vpn_public_ip
  type       = "ipsec.1"
  tags = { Name = "gw-to-scaleway" }
}

resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "main-vpn-gw" }
}

resource "aws_vpn_connection" "to_scaleway" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.scw_side.id
  type                = "ipsec.1"
  static_routes_only  = false # BGP activé
  tunnel1_preshared_key = var.scw_vpn_psk
  tunnel1_inside_cidr   = "169.254.131.116/30"
  tunnel2_preshared_key = var.scw_vpn_psk # à adapter si Scaleway fournit un PSK différent pour chaque tunnel
  tunnel2_inside_cidr   = "169.254.233.148/30"
  # Les options BGP sont gérées automatiquement si les ASN sont corrects
# Ajouter la variable pour le PSK Scaleway

}

# Outputs utiles pour la config côté Scaleway
output "aws_vpn_tunnel1_address" {
  value = aws_vpn_connection.to_scaleway.tunnel1_address
}
output "aws_vpn_tunnel2_address" {
  value = aws_vpn_connection.to_scaleway.tunnel2_address
}
output "aws_vpn_tunnel1_cgw_inside_address" {
  value = aws_vpn_connection.to_scaleway.tunnel1_cgw_inside_address
}
output "aws_vpn_tunnel1_vgw_inside_address" {
  value = aws_vpn_connection.to_scaleway.tunnel1_vgw_inside_address
}
output "aws_vpn_tunnel2_cgw_inside_address" {
  value = aws_vpn_connection.to_scaleway.tunnel2_cgw_inside_address
}
output "aws_vpn_tunnel2_vgw_inside_address" {
  value = aws_vpn_connection.to_scaleway.tunnel2_vgw_inside_address
}
output "aws_vpn_tunnel1_preshared_key" {
  value     = aws_vpn_connection.to_scaleway.tunnel1_preshared_key
  sensitive = true
}
output "aws_vpn_tunnel2_preshared_key" {
  value     = aws_vpn_connection.to_scaleway.tunnel2_preshared_key
  sensitive = true
}

# # --- COMPUTE (Free Tier Eligible) ---
# resource "aws_instance" "app_server" {
#   ami           = "ami-0080352554792694b" # Amazon Linux 2023 à Paris
#   instance_type = "t3.micro"
#   subnet_id     = aws_subnet.public.id
#   tags = { Name = "ec2-instance" }
# }

# # --- DATABASE (Free Tier Eligible si t3.micro & Single-AZ) ---
# resource "aws_security_group" "resolver_sg" {
#   name        = "resolver-sg"
#   vpc_id      = aws_vpc.main.id
#   description = "Allow Postgres access from the VPC"

#   ingress {
#     from_port   = 5432
#     to_port     = 5432
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.main.cidr_block]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = { Name = "resolver-sg" }
# }

# resource "aws_db_subnet_group" "postgres_subnet_group" {
#   name       = "postgres-subnet-group"
#   subnet_ids = [aws_subnet.public.id, aws_subnet.public_b.id]
#   tags = { Name = "postgres-subnet-group" }
# }

# resource "aws_db_instance" "postgres" {
#   allocated_storage       = 20
#   engine                  = "postgres"
#   engine_version          = "15"
#   instance_class          = "db.t3.micro"
#   db_name                 = "mydb"
#   username                = "adminuser"
#   password                = "ChangeMePlease123!"
#   db_subnet_group_name    = aws_db_subnet_group.postgres_subnet_group.name
#   vpc_security_group_ids  = [aws_security_group.resolver_sg.id]
#   skip_final_snapshot     = true
#   publicly_accessible     = false
#   multi_az                = false
#   tags = { Name = "postgres-db" }
# }

# # # --- ROUTE 53 OUTBOUND RESOLVER (Service Payant) ---
# # # Note : À n'activer que si nécessaire car très coûteux
# # resource "aws_route53_resolver_endpoint" "outbound" {
# #   name      = "outbound-resolver"
# #   direction = "OUTBOUND"

# #   security_group_ids = [aws_security_group.resolver_sg.id]

# #   ip_address {
# #     subnet_id = aws_subnet.public.id
# #   }

# #   ip_address {
# #     subnet_id = aws_subnet.public_b.id
# #   }
# #   # Il en faut généralement deux pour la haute disponibilité
# # }