resource "proxmox_virtual_environment_download_file" "os_generic_image" {
    node_name    = var.os.vm_node_name
    content_type = "iso"
    datastore_id = "local"

    file_name          = var.os.vm_base_image
    url                = var.os.vm_base_url
    checksum           = var.os.vm_base_image_checksum
    checksum_algorithm = var.os.vm_base_image_checksum_alg
}
	
resource "proxmox_virtual_environment_file" "cloud-init" {
    for_each = toset(distinct([for k, v in var.images : k]))
    
    node_name    = var.images[each.key].vm_node_name
    content_type = "snippets"
    datastore_id = "local"

    source_raw {
        data = templatefile("${path.module}/resources/cloud-init/vm-init.yaml.tftpl", {
            hostname      = each.key
            username      = var.images[each.key].vm_user
            pub-keys      = var.images[each.key].vm_ssh_public_key_files
            run-cmds      = var.images[each.key].vm_run_cmds
        })

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
        user_data_file_id = proxmox_virtual_environment_file.cloud-init[each.key].id
    }
}

