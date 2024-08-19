terraform {
    source = "../../cluster"
    commands = ["plan", "apply", "destroy"]

    arguments = [
        "-var-file=common.tfvars"
    ]
}

inputs = {
    location = "northeurope"
    resource_group_name = "prod-playground"
    node_count = "1"
    vpc_name = "prod-cluster-network"
    vpc_address_space = ["10.16.0.0/16"]
    dns_prefix = "slaanesh"
    env = "prod"
    subnets = ["10.16.0.0/20", "10.16.16.0/20", "10.16.128.0/20"]
    pod_cidr = "10.16.32.0/20"
    service_cidr = "10.16.64.0/20"
    dns_service_ip = "10.16.64.201"
    default_vm_size = "Standard_D2_v2"
    default_node_pool_name = "slaaneshp1"
    vm_size_gpu = "Standard_NC4as_T4_v3"
}
