# providers.tf
provider "azurerm" {
  features {}
}

# main.tf
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.location

  # lifecycle {
  #   prevent_destroy = true
  # }

}

# Virtual Network
resource "azurerm_virtual_network" "cluster_vpc" {
  name                = var.vpc_name
  address_space       = var.vpc_address_space
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Subnet 1
resource "azurerm_subnet" "cluster_subnet" {
  count = length(var.subnets)
  name                 = "${var.env}-subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.cluster_vpc.name
  address_prefixes     = [var.subnets[count.index]]

  depends_on = [ azurerm_virtual_network.cluster_vpc ]
}


# other resources will go here
resource "azurerm_kubernetes_cluster" "test-cluster" {
    location            = azurerm_resource_group.resource_group.location
    name                = "${var.env}-cluster"
    resource_group_name = azurerm_resource_group.resource_group.name
    dns_prefix          = "${var.env}-${var.dns_prefix}"


    
    identity {
      type = "SystemAssigned"
    }

    default_node_pool {
      name       = var.default_node_pool_name
      vm_size    = var.default_vm_size
      node_count = var.node_count
      vnet_subnet_id = azurerm_subnet.cluster_subnet[0].id
    
    }

    
    # linux_profile {
    #   admin_username = var.username

    #   ssh_key {
    #     key_data = azapi_resource_action.ssh_public_key_gen.output.publicKey
    #   }
    # }
    network_profile {
      network_plugin    = "kubenet"
      load_balancer_sku = "standard"
      pod_cidr = var.pod_cidr
      service_cidr =  var.service_cidr
      dns_service_ip = var.dns_service_ip
    }

    automatic_channel_upgrade = "stable"

    depends_on = [ azurerm_resource_group.resource_group, azurerm_subnet.cluster_subnet ]
}