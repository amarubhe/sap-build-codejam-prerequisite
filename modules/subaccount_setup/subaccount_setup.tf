# ------------------------------------------------------------------------------------------------------
# Define the required providers for this module
# ------------------------------------------------------------------------------------------------------
terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
    }
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
    }
  }
}


###############################################################################################
# Generating random ID for subdomain
###############################################################################################
#resource "random_uuid" "uuid" {}

locals {
#  random_uuid       = random_uuid.uuid.result
#  subaccount_name   = var.subaccount_name
# existing_subaccount   = one([for acc in data.btp_subaccounts.all.values : acc if acc.name == var.subaccount_name])
#  is_new_subaccount = local.existing_subaccount == null ? true : false
  
}

resource "random_string" "subdomain_random_part" {
  length           = 8
  upper            = false
  numeric          = true
  lower            = true  
  special          = false
}

data "btp_subaccounts" "all" {}

###
# Creation of subaccount
###
resource "btp_subaccount" "user_subaccount" {
  name      = var.subaccount_name
  subdomain = random_string.subdomain_random_part.result # replace(lower(random_string.subdomain_random_part.result) +"trial"," ","-")
  region    = lower(var.region)
#  count     = local.is_new_subaccount ? 1 : 0
  depends_on = [ data.btp_subaccounts.all, random_string.subdomain_random_part ]
}

# locals {
#    user_subaccount = local.is_new_subaccount  ? btp_subaccount.user_subaccount[0] : local.existing_subaccount
# }





# ------------------------------------------------------------------------------------------------------
# Creation of Cloud Foundry environment
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
# CLOUDFOUNDRY PREPARATION
# ------------------------------------------------------------------------------------------------------
#

# ------------------------------------------------------------------------------------------------------
# Fetch all available environments for the subaccount
# ------------------------------------------------------------------------------------------------------
data "btp_subaccount_environments" "all" {
  subaccount_id =btp_subaccount.user_subaccount.id
}

# ------------------------------------------------------------------------------------------------------
# Take the landscape label from the first CF environment if no environment label is provided
# ------------------------------------------------------------------------------------------------------
resource "null_resource" "cache_target_environment" {
  triggers = {
    label = length(var.environment_label) > 0 ? var.environment_label : [for env in data.btp_subaccount_environments.all.values : env if env.service_name == "cloudfoundry" && env.environment_type == "cloudfoundry"][0].landscape_label
  }

  lifecycle {
    ignore_changes = all
  }
}


# locals {
#   existing_cf   = one([for cf_env in data.btp_subaccount_environment_instances.all.values : cf_env if cf_env.name == local.user_subaccount.subdomain])
# }

# creates a cloud foundry environment in a given account
resource "btp_subaccount_environment_instance" "cloudfoundry" {
  subaccount_id    = btp_subaccount.user_subaccount.id
  name             = btp_subaccount.user_subaccount.subdomain
  environment_type = "cloudfoundry"
  service_name     = "cloudfoundry"
  plan_name        = "trial"
  landscape_label  = null_resource.cache_target_environment.triggers.label
  parameters = jsonencode({
    instance_name = btp_subaccount.user_subaccount.subdomain
    memory        = 1024
  })
#   count     = local.is_new_subaccount ? 1 : 0
  depends_on = [btp_subaccount.user_subaccount ]
}

# locals {
#    user_cloudfoundry_env = local.is_new_subaccount  ? btp_subaccount_environment_instance.cloudfoundry[0] : local.existing_cf
# }
data "cloudfoundry_org" "org_details" {
    name = btp_subaccount.user_subaccount.subdomain
    depends_on = [ btp_subaccount_environment_instance.cloudfoundry ]
}


# create a cloudfoundry Space in the created subaccount
resource "cloudfoundry_space" "space" {
  name      = "dev"
  org       =  data.cloudfoundry_org.org_details.id
#  count     =  local.is_new_subaccount ? 1 : 0
  depends_on = [ data.cloudfoundry_org.org_details]
  
}


# ------------------------------------------------------------------------------------------------------
# Create the CF users
# ------------------------------------------------------------------------------------------------------
resource "cloudfoundry_space_role" "manager" {
  space      = cloudfoundry_space.space.id
  type       = "space_manager"
  username =  var.cf_org_admin
  depends_on = [cloudfoundry_space.space]
}


# Read a subaccount by region and subdomain
# data "btp_subaccount" "my_subaccount" {
#   region    = var.region
#   subdomain = "my-subaccount-subdomain"
# }
