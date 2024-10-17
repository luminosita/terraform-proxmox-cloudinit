resource "proxmox_virtual_environment_download_file" "os_generic_image" {
    node_name    = var.os.vm_node_name
    content_type = "iso"
    datastore_id = "local"

    file_name          = var.os.vm_base_image
    url                = var.os.vm_base_url
    checksum           = var.os.vm_base_image_checksum
    checksum_algorithm = var.os.vm_base_image_checksum_alg
    decompression_algorithm = var.os.vm_decompression_algorithm
}

locals {
    cloud-init-template-data = {
        for k, v in var.images : k => var.images[k].vm_cloud_init ? templatefile("${path.module}/resources/cloud-init/vm-init.yaml.tftpl", {
            hostname      = var.images[k].vm_name
            username      = var.images[k].vm_ci_user
            pub-keys      = var.images[k].vm_ci_ssh_public_key_files
            run-cmds-enabled        = var.images[k].vm_ci_run_cmds.enabled
            run-cmds-content        = var.images[k].vm_ci_run_cmds.content
            packages-enabled        = var.images[k].vm_ci_packages.enabled
            packages-content        = var.images[k].vm_ci_packages.content
            write-files-enabled     = var.images[k].vm_ci_write_files.enabled
            write-files-content     = var.images[k].vm_ci_write_files.content
            reboot-enabled          = var.images[k].vm_ci_reboot_enabled
        }) : null
    }

    cloud-init-data = {
        for k, v in var.images : k => var.images[k].vm_cloud_init_data == null ? local.cloud-init-template-data[k] : var.images[k].vm_cloud_init_data
    }
}
	
resource "proxmox_virtual_environment_file" "cloud-init" {
    for_each = toset(distinct([for k, v in var.images: k if v.vm_cloud_init]))
    
    node_name    = var.images[each.key].vm_node_name
    content_type = "snippets"
    datastore_id = "local"

    source_raw {
        data = local.cloud-init-data[each.key]

        file_name = "${each.key}-${var.images[each.key].vm_id}-cloudinit.yaml"
    }
}

resource "proxmox_virtual_environment_vm" "vm" {
    for_each = toset(distinct([for k, v in var.images : k]))

    node_name = var.images[each.key].vm_node_name

    name        = each.key
    on_boot     = true
    vm_id       = var.images[each.key].vm_id

    machine       = "q35"
    scsi_hardware = "virtio-scsi-single"
    bios          = "ovmf"

    cpu {
        cores = 4
        type  = "host"
    }

    memory {
        dedicated = 1024
    }

    network_device {
        bridge      = "vmbr0"
#        mac_address = local.ctrl_mac_address[count.index]
    }

    efi_disk {
        datastore_id = "local-zfs"
        file_format  = "raw" // To support qcow2 format
        type         = "4m"
    }

    disk {
        datastore_id = "local-zfs"
        file_id      = proxmox_virtual_environment_download_file.os_generic_image.id
        interface    = "scsi0"
        cache        = "writethrough"
        discard      = "on"
        ssd          = true
        size         = 10
    }

    serial_device {
        device = "socket"
    }

    vga {
        type = "serial0"
    }

    boot_order = ["scsi0"]
    
    agent {
        enabled = true
    }

    operating_system {
        type = "l26" # Linux Kernel 2.6 - 6.X.
    }

    initialization {
        ip_config {
            ipv4 {
                address = "dhcp"
            }
        }

        datastore_id      = "local-zfs"
        user_data_file_id = var.images[each.key].vm_cloud_init ? proxmox_virtual_environment_file.cloud-init[each.key].id : null
    }

#     connection {
#         type            = "ssh"
#         user            = var.images[each.key].vm_user
#         host            = self.ipv4_address
#         timeout         = "1m"
#         agent           = false
#         private_key     = file(var.hcloud.ssh_private_key_file)    
#     }

#     provisioner "remote-exec" {
#         inline = [ "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for Cloud-Init...'; sleep 1; done" ]
#     }
}

