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

variable "vpc_name" {
  type = string
  description = "Name of VPC"
}

variable vpc_address_space {
  type = list(string)
  description = "Addresses in this vpc"
}

variable dns_prefix  {
  type = string
  description = "Prefix for dns names for this k8s cluster"
}

variable "subnets" {
  type = list(string)
  description = "list of subnets"
}

variable "env" {
  type = string
  description = "name of environment"
}

variable pod_cidr {
  type = string
  description = "List of pod cidrs to launch pods in"
}

variable service_cidr {
  type = string
  description = "List of service cidrs to launch k8s service with"
}

variable dns_service_ip {
  type = string
  description = "Ip within range of vpc for dns service"
}

variable "default_vm_size" {
  type = string
  description = "Size of vm for k8s cluster"
}

variable "default_node_pool_name" {
  type = string
}

variable "tags" {
  type = map
}

variable "common_tags" {
  type = map
}

variable vm_size_gpu {
  type = string
}