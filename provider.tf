terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    btp = {
      source  = "SAP/btp"
      version = "1.12.0"
    }
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
      version = "1.6.0"
    }
  }
}

# Configure the BTP Provider
provider "btp" {
  globalaccount = var.globalaccount
  username      = var.admin_email
  password      = var.admin_password
}

provider "cloudfoundry" {
  #api_url = module.subaccount.cloudfoundry.api_endpoint
  api_url =   "https://api.cf.us10-001.hana.ondemand.com"
  user          = var.admin_email
  password      = var.admin_password
}