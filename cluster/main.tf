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
  tags = merge(var.common_tags, var.tags)

}

# Virtual Network
resource "azurerm_virtual_network" "cluster_vpc" {
  name                = var.vpc_name
  address_space       = var.vpc_address_space
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  tags = merge(var.common_tags, var.tags)

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


resource "azurerm_public_ip" "ingress-ip" {
  name                = "${var.env}-ingress-ip"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"

  sku = "Standard" #Basic

    tags = merge(var.common_tags, var.tags)
}

# Need to create this since they are reused in multiple config settings in azurerm_application_gateway resource
locals {
  backend_address_pool_name      = "${var.env}-${azurerm_virtual_network.cluster_vpc.name}-beap"
  frontend_port_name             = "${var.env}-${azurerm_virtual_network.cluster_vpc.name}-feport"
  frontend_ip_configuration_name = "${var.env}-${azurerm_virtual_network.cluster_vpc.name}-feip"
  http_setting_name              = "${var.env}-${azurerm_virtual_network.cluster_vpc.name}-be-htst"
  listener_name                  = "${var.env}-${azurerm_virtual_network.cluster_vpc.name}-httplstn"
  request_routing_rule_name      = "${var.env}-${azurerm_virtual_network.cluster_vpc.name}-rqrt"
  redirect_configuration_name    = "${var.env}-${azurerm_virtual_network.cluster_vpc.name}-rdrcfg"
}

resource azurerm_application_gateway ingress-gw {
  name                = "${var.env}-cluster-ingress-gw"
  resource_group_name = azurerm_resource_group.resource_group.name

  location            = azurerm_resource_group.resource_group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "ingress-gateway-ip-configuration"
    subnet_id =  azurerm_subnet.cluster_subnet[2].id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.ingress-ip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  depends_on = [ azurerm_public_ip.ingress-ip, azurerm_resource_group.resource_group, azurerm_virtual_network.cluster_vpc, azurerm_subnet.cluster_subnet ]

  tags = merge(var.common_tags, var.tags)
}

# other resources will go here
resource "azurerm_kubernetes_cluster" "test-cluster" {
    location            = azurerm_resource_group.resource_group.location
    name                = "${var.env}-cluster"
    resource_group_name = azurerm_resource_group.resource_group.name
    dns_prefix          = "${var.env}-${var.dns_prefix}"

    tags = merge(var.common_tags, var.tags)

    # Ingress application gateway needs its own subnet
    ingress_application_gateway {
      # gateway_name = "${var.env}-cluster-ingress-gw"
      # subnet_id = azurerm_subnet.cluster_subnet[2].id
      gateway_id = azurerm_application_gateway.ingress-gw.id

      
    }


    sku_tier = "Free"
    
    
    identity {
      type = "SystemAssigned"
    }

    default_node_pool {
      name       = var.default_node_pool_name
      vm_size    = var.default_vm_size
      node_count = var.node_count
      vnet_subnet_id = azurerm_subnet.cluster_subnet[0].id
      enable_auto_scaling = true
      max_count = 3
      min_count = 1
      tags = merge(var.common_tags, var.tags)

    }

    
      # Enable virtual node (ACI connector) for Linux
      # Virtual nodes needs their own subnet
      aci_connector_linux {
        subnet_name = azurerm_subnet.cluster_subnet[1].name

      }

    network_profile {
      network_plugin    = "kubenet"
      load_balancer_sku = "standard"
      pod_cidr = var.pod_cidr
      service_cidr =  var.service_cidr
      dns_service_ip = var.dns_service_ip
    }

    automatic_channel_upgrade = "stable"

    depends_on = [ azurerm_resource_group.resource_group, azurerm_subnet.cluster_subnet, azurerm_application_gateway.ingress-gw, azurerm_public_ip.ingress-ip]
}


resource "azurerm_role_assignment" "aks_agic_integration" {
  scope = azurerm_virtual_network.cluster_vpc.id
  role_definition_name = "Network Contributor"
  principal_id = azurerm_kubernetes_cluster.test-cluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id

}

## This might be unnecessary when agw have the same role on the vpc.
resource "azurerm_role_assignment" "agw_integration" {
  scope = azurerm_subnet.cluster_subnet[2].id
  role_definition_name = "Network Contributor"
  principal_id =  azurerm_kubernetes_cluster.test-cluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}


resource "azurerm_role_assignment" "aci_connector_linux_integration" {
  scope = azurerm_virtual_network.cluster_vpc.id
  role_definition_name = "Network Contributor"
  principal_id =  azurerm_kubernetes_cluster.test-cluster.aci_connector_linux[0].connector_identity[0]["object_id"]
}








# THIs does nothing you need aci_connector_linux_integration
# resource "azurerm_role_assignment" "example" {
#   scope                = azurerm_virtual_network.cluster_vpc.id
#   role_definition_name = "Network Contributor"
#   principal_id         = azurerm_kubernetes_cluster.test-cluster.identity.0.principal_id
# }