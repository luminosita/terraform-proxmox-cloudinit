output "ip_addresses" {
    value = {
        for k, v in var.images : k => proxmox_virtual_environment_vm.vm[k].ipv4_addresses[1][0]
    }
}