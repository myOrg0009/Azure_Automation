variable "name"                { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "dns_prefix"          { type = string }
variable "node_count"          { 
    type = number  
    default = 2 
    }
variable "node_vm_size"        { 
    type = string  
    default = "Standard_D2s_v3" 
    }
variable "subnet_id"           { type = string }
variable "acr_id"              { type = string }
variable "tags"                { 
    type = map(string) 
    default = {} 
    }
variable "log_analytics_workspace_id"  { type = string }
variable "admin_group_object_id"       { type = string }
