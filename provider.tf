terraform {
  required_providers {
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
  api_url = module.trialaccount.cloudfoundry.api_endpoint
}