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
  default = 65010
}

variable "cgw_ip" {
  type    = string
  default = ""
}

variable "claranet_plage" {
  type    = list(string)
  default = [""]

}
