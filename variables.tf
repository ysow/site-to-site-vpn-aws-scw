variable "scw_access_key" {
  default = ""
}

variable "scw_secret_key" {
  default = ""
}
variable "scw_project_id" {
  default = ""
}

variable "region" {
  default = "fr-par"
}

variable "cgw_asn" {
  type    = number
  default = 65000
}

variable "cgw_ip" {
  type    = string
  default = ""
}

variable "aws_plage" {
  type    = list(string)
  default = ["10.1.0.0/16"]

}

variable "scw_vpn_public_ip" {
  type    = string
  default = ""

}
variable "scw_vpn_psk" {
  type      = string
  sensitive = true
  description = "PSK généré côté Scaleway à utiliser pour le tunnel AWS."
}