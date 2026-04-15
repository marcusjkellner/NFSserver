


variable "api_token" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  type = string
}
variable "endpoint" {
  type    = string
}
variable "nodename" {
  type    = string
}
variable "VMTemplateID" {
  type    = number
}

variable "vm_gateway" {
  type    = string
}

variable "controller_name" {
  type    = string
  default = "ansible-controller"
}

variable "controller_ip" {
  type    = string
}

variable "controller_username" {
  type    = string
  default = "controller"
}

variable "controller_vmid" {
  type    = number
  default = 2041
}
# Fileserver variables
variable "fileserver_name" {
  type    = string
  default = "fileserver"
}

variable "fileserver_ip" {
  type    = string
}

variable "fileserver_username" {
  type    = string
  default = "fileserver"
}

variable "fileserver_vmid" {
  type    = number
  default = 2042
}

# Client Legal variables
variable "clientLegal_name" {
  type    = string
  default = "client-legal"
}

variable "clientLegal_ip" {
  type    = string
}

variable "clientLegal_username" {
  type    = string
  default = "user_legal"
}

variable "clientLegal_vmid" {
  type    = number
  default = 2043
 }

# Client Sales variables
variable "clientSales_name" {
  type    = string
  default = "client-sales"
}

variable "clientSales_ip" {
  type    = string
}

variable "clientSales_username" {
  type    = string
  default = "user_sales"
}

variable "clientSales_vmid" {
  type    = number
  default = 2044
 }
 