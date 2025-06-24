output "id" {
  description = "The ID of the subaccount"
  value       = btp_subaccount.user_subaccount.id
  depends_on = [ btp_subaccount.user_subaccount ]
}

output "region" {
  description = "The region of the subaccount"
  value       =  btp_subaccount.user_subaccount.region
  depends_on = [ btp_subaccount.user_subaccount ]
}

output "cf_org_id" {
  description = "The platform ID of the subaccount"
  value       = btp_subaccount_environment_instance.cloudfoundry.platform_id
  depends_on = [ btp_subaccount_environment_instance.cloudfoundry ]
  
}

output "cf_api_endpoint" {
  value       = lookup(jsondecode(btp_subaccount_environment_instance.cloudfoundry.labels), "API Endpoint", "not found")
  description = "API endpoint of the Cloud Foundry environment."
}

output "cloudfoundry" {
  description = "The cloudfoundry environment which is by default created for your subaccount"
  depends_on = [btp_subaccount_environment_instance.cloudfoundry ]
  value = {
    api_endpoint = lookup(jsondecode(btp_subaccount_environment_instance.cloudfoundry.labels), "API Endpoint")
    org_id       = lookup(jsondecode(btp_subaccount_environment_instance.cloudfoundry.labels), "Org ID")
    org_name     = lookup(jsondecode(btp_subaccount_environment_instance.cloudfoundry.labels), "Org Name")
    region       = replace(btp_subaccount_environment_instance.cloudfoundry.landscape_label, "/cf-/", "")
  }
}

# output "id" {
#   description = "The ID of the trial account"
#   value       = one(btp_subaccount.user_subaccount).id
# }
