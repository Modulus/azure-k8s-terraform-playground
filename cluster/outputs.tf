output "connector" {
  value = azurerm_kubernetes_cluster.test-cluster.aci_connector_linux[0].connector_identity[0]["object_id"]
}

output "public_ip" {
    value = azurerm_public_ip.ingress-ip.ip_address
}