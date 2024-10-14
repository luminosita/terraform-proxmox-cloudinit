variable "os" {
    type        = object({
        vm_node_name = string

        vm_base_url                 = string
        vm_base_image               = string
        vm_base_image_checksum      = string
        vm_base_image_checksum_alg  = string
    })
}

variable "images" {
    type        = map(object({
        vm_id               = number

        vm_node_name        = string

        vm_cloud_init       = bool
        vm_cloud_init_data  = optional(string)

        vm_ci_packages  = optional(object({
            enabled = optional(bool)
            content = optional(list(string))
        }), {
            enabled = true,
            content = null
        })

        vm_ci_write_files  = optional(object({
            enabled = optional(bool)
            content = optional(list(object({
                path = string
                content = string
            })))
        }), {
            enabled = true,
            content = null
        })

        vm_ci_run_cmds  = optional(object({
            enabled = optional(bool)
            content = optional(list(string))
        }), {
            enabled = true,
            content = null
        })

        vm_ci_reboot_enabled = optional(bool, false)

        vm_user = string
        vm_ssh_public_key_files = list(string)
    }))
}
