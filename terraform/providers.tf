provider "proxmox" {
  endpoint  = "https://192.168.2.31:8006"
  api_token = var.api_token
  insecure  = true
}