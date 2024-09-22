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
        vm_id                       = number

        vm_node_name = string

        vm_user = string
        vm_ssh_public_key_files = list(string)
    }))
}

