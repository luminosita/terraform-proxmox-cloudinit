variable "os" {
    type        = object({
        vm_node_name = string

        vm_base_url                 = string
        vm_base_image               = string
        vm_base_image_checksum      = string
        vm_base_image_checksum_alg  = string
        vm_decompression_algorithm  = optional(string)
    })
}

variable "images" {
    type        = map(object({
        vm_id               = number

        vm_name        = string
        vm_node_name        = string

        vm_cloud_init       = optional(bool, false)
        vm_cloud_init_data  = optional(string)

        vm_ci_user = optional(string)
        vm_ci_ssh_public_key_files = optional(list(string))

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
                permissions = optional(string, "0644")
                encoding = optional(string, "text/plain")
                owner = optional(string, "root:root")
                append = optional(bool, false)
                defer = optional(bool, false)
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

        vm_ci_reboot_enabled = optional(bool, true)
    }))
}
