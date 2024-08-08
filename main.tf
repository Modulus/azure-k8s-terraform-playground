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

# other resources will go here
resource "azurerm_kubernetes_cluster" "test-cluster" {
    location            = azurerm_resource_group.resource_group.location
    name                = "test-cluster"
    resource_group_name = azurerm_resource_group.resource_group.name
    dns_prefix          = "test"

    identity {
      type = "SystemAssigned"
    }

    default_node_pool {
      name       = "agentpool"
      vm_size    = "Standard_D2_v2"
      node_count = var.node_count
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
    }

    automatic_channel_upgrade = "stable"

    depends_on = [ azurerm_resource_group.resource_group ]
}