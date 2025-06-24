variable "admin_email" {
    description = "BTP admin user email"
    type        = string
}

variable "admin_password" {
    description = "BTP admin password"
    type        = string
    sensitive   = true
}

variable "globalaccount" {
  type        = string
  description = "The globalaccount subdomain.(e.g zzzzzztrial-ga)"
}

variable "subaccount_name" {
  type        = string
  description = "The subaccount name ."
  default     = "dept-XYZ"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_\\-]{1,200}", var.subaccount_name))
    error_message = "Provide a valid project account name."
  }
}


variable "custom_idp_origin" {
  type        = string
  description = "Defines the custom IDP origin for the role collection"
  default     = "sap.custom"
}

