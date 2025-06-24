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
  subdomain = random_string.subdomain_random_part.result 
  region    = lower(var.region)
  depends_on = [ data.btp_subaccounts.all, random_string.subdomain_random_part ]
}

# ------------------------------------------------------------------------------------------------------
# Creation of Cloud Foundry environment
# ------------------------------------------------------------------------------------------------------

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
  depends_on = [btp_subaccount.user_subaccount ]
}


data "cloudfoundry_org" "org_details" {
    name = btp_subaccount.user_subaccount.subdomain
    depends_on = [ btp_subaccount_environment_instance.cloudfoundry ]
}


# create a cloudfoundry Space in the created subaccount
resource "cloudfoundry_space" "space" {
  name      = "dev"
  org       =  data.cloudfoundry_org.org_details.id
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


