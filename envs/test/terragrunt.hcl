terraform {
    source = "../../cluster"
}

inputs = {
    location = "northeurope"
    resource_group_name = "test-playground"
    node_count = "1"
    vpc_name = "test-cluster-network"
    vpc_address_space = ["10.1.0.0/16"]
    dns_prefix = "khorne"
    env = "test"
    subnets = ["10.1.0.0/20", "10.1.16.0/20", "10.1.128.0/20"]
    pod_cidr = "10.1.32.0/20"
    service_cidr = "10.1.64.0/20"
    dns_service_ip = "10.1.64.201"
    default_vm_size = "Standard_D2_v2"
    default_node_pool_name = "khornepool1"
}
