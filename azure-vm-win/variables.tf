variable "rgname" {
  description = "resource group name"
  default     = "gimmequick-vm-win"
}

variable "location" {
  description = "location name"
  default     = "West Europe"
}

variable "snapshot_id" {
  description = "ID of snapshot to create Windows VM from."
  default = ""
}