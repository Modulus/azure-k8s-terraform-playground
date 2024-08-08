# variables.tf
variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Location of resources" # Display name West Europe
}

variable "node_count" {
  type = number
  description = "Number of nodes in nodepools"
}