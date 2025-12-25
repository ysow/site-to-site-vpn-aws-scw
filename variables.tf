variable "scw_access_key" {
  default = "SCW6QPPC28Q0SCKYCMJ0"
}

variable "scw_secret_key" {
  default = "dd1c96be-3922-4e63-8d58-4a6687971aba"
}
variable "scw_project_id" {
  default = "50fc0d26-96ad-4d8b-8b37-aeff2d19396a"
}

variable "region" {
  default = "fr-par"
}

variable "cgw_asn" {
  type    = number
  default = 65010
}

variable "cgw_ip" {
  type    = string
  default = "51.159.171.151"
}

variable "claranet_plage" {
  type    = list(string)
  default = ["0.0.0.0/0"]

}
