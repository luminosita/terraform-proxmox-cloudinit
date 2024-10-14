output "result" {
    value = {
        for k, v in var.images : k => {
            ip = proxmox_virtual_environment_vm.vm[k].ipv4_addresses[1][0]
            cloud-init = local.cloud-init-data[k]
        }
    }
}