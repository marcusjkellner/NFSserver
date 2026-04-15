variable "api_token" {
  type      = string
  sensitive = true
}

variable "vm_gateway" {
  type    = string
  default = "192.168.2.1"
}

variable "ssh_public_key" {
  type = string
}

variable "controller_name" {
  type    = string
  default = "controller"
}

variable "controller_ip" {
  type    = string
  default = "192.168.2.41/24"
}

variable "controller_username" {
  type    = string
  default = "controller"
}

variable "controller_vmid" {
  type    = number
  default = 2000
}
# Fileserver variables
variable "fileserver_name" {
  type    = string
  default = "fileserver"
}

variable "fileserver_ip" {
  type    = string
  default = "192.168.2.42/24"
}

variable "fileserver_username" {
  type    = string
  default = "fileserver"
}

variable "fileserver_vmid" {
  type    = number
  default = 2001
}

# Webserver variables
variable "webserver_name" {
  type    = string
  default = "webserver"
}

variable "webserver_ip" {
  type    = string
  default = "192.168.2.43/24"
}

variable "webserver_username" {
  type    = string
  default = "webserver"
}

variable "webserver_vmid" {
  type    = number
  default = 2002
 }