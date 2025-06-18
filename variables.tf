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

# variable "custom_idp" {
#   type        = string
#   description = "Defines the custom IDP to be used for the subaccount(e.g zzzzzz.trial-accounts.ondemand.com)"
#   default     = "azw61poxu.trial-accounts.ondemand.com"
#   validation {
#     condition     = can(regex("^[a-z-]", var.custom_idp))
#     error_message = "Please enter a valid entry for the custom-idp of the subaccount."
#   }
# }

variable "custom_idp_origin" {
  type        = string
  description = "Defines the custom IDP origin for the role collection"
  default     = "sap.custom"
}

