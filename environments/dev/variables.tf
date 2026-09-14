variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-platform-dev"
}

variable "environment" {
  type    = string
  default = "dev"
}
variable "admin_group_object_id"       { type = string }

variable "acr_name" {
  type        = string
  description = "Globally-unique ACR name for this environment (alphanumeric only, 5-50 chars)."
}

variable "node_count" {
  type = number 
  default = 2 
  }