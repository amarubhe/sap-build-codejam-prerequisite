# global account
variable "globalaccount" {
  type        = string
  description = "The globalaccount subdomain."
}

# subaccount
variable "subaccount_name" {
  type        = string
  description = "The subaccount name."
}

variable "environment_label" {
  type        = string
  description = "In case there are multiple environments available for a subaccount, you can use this label to choose with which one you want to go. If nothing is given, we take by default the first available."
  default     = ""
}

variable "cf_org_admin" {
  type        = string
  description = "Defines the colleague who are added to the Cloud Foundry organization as users."
}

# Region
variable "region" {
  type        = string
  description = "The region where the project account shall be created in."
  default     = "us10"
  validation {
    condition     = contains(["us10", "ap21"], var.region)
    error_message = "Region must be one of us10 or ap21"
  }
}


