variable "deployment" {
    type = object({
        name-prefix     = string
        vpc-cidr        = string
        public-cidrs    = list(string)
        private-cidrs   = list(string)
        ubuntu-image-id      = string
        max-instances   = number
        min-instances   = number
        starting-instances = number
        region          = string
    })
}

variable "db_password" {
    type = string
}