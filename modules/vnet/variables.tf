variable "name"                { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "address_space"       { type = list(string) }
variable "subnet_name"         { type = string }
variable "subnet_prefix"       { type = string }
variable "tags"                { type = map(string)}