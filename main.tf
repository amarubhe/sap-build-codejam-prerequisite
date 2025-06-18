

# looks up the id of the pre-created trial account
module "trialaccount" {
  source = "./modules/btp_trial_data"
}

# #
# # ------------------------------------------------------------------------------------------------------
# # Setup identity
# # ------------------------------------------------------------------------------------------------------
# Entitle
resource "btp_subaccount_entitlement" "sap-identity-services-onboarding" {
  subaccount_id =  module.trialaccount.id
  service_name  = "sap-identity-services-onboarding"
  plan_name     = "default"
}
# Subscribe
resource "btp_subaccount_subscription" "sap-identity-services-onboarding" {
  subaccount_id =  module.trialaccount.id
  app_name      = "sap-identity-services-onboarding"
  plan_name     = "default"
  depends_on    = [btp_subaccount_entitlement.sap-identity-services-onboarding]
}

locals {
  # Extract the subdomain from the custom IDP URL
  custom_idp_subscription_url = btp_subaccount_subscription.sap-identity-services-onboarding.subscription_url
}

# ------------------------------------------------------------------------------------------------------
# Assign custom IDP to sub account
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_trust_configuration" "simple" {
  depends_on    = [btp_subaccount_subscription.sap-identity-services-onboarding]
  subaccount_id     = module.trialaccount.id
  identity_provider = trimsuffix(trimprefix(local.custom_idp_subscription_url, "https://"), "/admin")
}


# ------------------------------------------------------------------------------------------------------
# Prepare and setup app: SAP Build Apps
# ------------------------------------------------------------------------------------------------------
# Entitle subaccount for usage of app  destination SAP Build Workzone, standard edition
resource "btp_subaccount_entitlement" "sap_build_apps" {
  subaccount_id = module.trialaccount.id
  service_name  = "sap-build-apps"
  plan_name     = "free"
  amount        = 1
}

# ------------------------------------------------------------------------------------------------------
# Create a subscription to the SAP Build Apps
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_subscription" "sap-build-apps_free" {
  depends_on    = [btp_subaccount_trust_configuration.simple]
  subaccount_id = module.trialaccount.id
  app_name      = "sap-appgyver-ee"
  plan_name     = "free"
  timeouts = {
    create = "10m"
    update = "10m"
  }
}

# ------------------------------------------------------------------------------------------------------
# Get all roles in the subaccount
# ------------------------------------------------------------------------------------------------------
data "btp_subaccount_roles" "all" {
  subaccount_id = module.trialaccount.id
  depends_on    = [btp_subaccount_subscription.sap-build-apps_free]
}

# ------------------------------------------------------------------------------------------------------
# Setup for role collection BuildAppsAdmin
# ------------------------------------------------------------------------------------------------------
# Create the role collection
resource "btp_subaccount_role_collection" "build_apps_BuildAppsAdmin" {
  subaccount_id =  module.trialaccount.id
  name          = "BuildAppsAdmin"

  roles = [
    for role in data.btp_subaccount_roles.all.values : {
      name                 = role.name
      role_template_app_id = role.app_id
      role_template_name   = role.role_template_name
    } if contains(["BuildAppsAdmin"], role.name)
  ]
}

# ------------------------------------------------------------------------------------------------------
# Assign users to the role collection
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_role_collection_assignment" "build_apps_BuildAppsAdmin" {
  depends_on           = [btp_subaccount_role_collection.build_apps_BuildAppsAdmin]
  subaccount_id        = module.trialaccount.id
  role_collection_name = "BuildAppsAdmin"
  user_name            = var.admin_email
  origin               = var.custom_idp_origin
}

# ------------------------------------------------------------------------------------------------------
# Setup for role collection BuildAppsDeveloper
# ------------------------------------------------------------------------------------------------------
# Create the role collection
resource "btp_subaccount_role_collection" "build_apps_BuildAppsDeveloper" {
  subaccount_id = module.trialaccount.id
  name          = "BuildAppsDeveloper"

  roles = [
    for role in data.btp_subaccount_roles.all.values : {
      name                 = role.name
      role_template_app_id = role.app_id
      role_template_name   = role.role_template_name
    } if contains(["BuildAppsDeveloper"], role.name)
  ]
}

# ------------------------------------------------------------------------------------------------------
# Assign users to the role collection
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_role_collection_assignment" "build_apps_BuildAppsDeveloper" {
  depends_on           = [btp_subaccount_role_collection.build_apps_BuildAppsDeveloper]
  subaccount_id        = module.trialaccount.id
  role_collection_name = "BuildAppsDeveloper"
  user_name            = var.admin_email
  origin               = var.custom_idp_origin
}


# ------------------------------------------------------------------------------------------------------
# Prepare and setup app: SAP Build Workzone, standard edition
# ------------------------------------------------------------------------------------------------------
# Entitle subaccount for usage of app  destination SAP Build Workzone, standard edition
resource "btp_subaccount_entitlement" "build_workzone" {
  subaccount_id = module.trialaccount.id
  service_name  = "SAPLaunchpad"
  plan_name     = "standard"
}
# Create app subscription to SAP Build Workzone, standard edition (depends on entitlement)
resource "btp_subaccount_subscription" "build_workzone" {
  subaccount_id = module.trialaccount.id
  app_name      = "SAPLaunchpad"
  plan_name     = "standard"
  depends_on    = [btp_subaccount_entitlement.build_workzone, btp_subaccount_trust_configuration.simple]
}

# ------------------------------------------------------------------------------------------------------
# Assign users to the role collection
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_role_collection_assignment" "launchpad_admin" {
  depends_on           = [btp_subaccount_subscription.build_workzone]
  subaccount_id        = module.trialaccount.id
  role_collection_name = "Launchpad_Admin"
  user_name            = var.admin_email
  origin               = var.custom_idp_origin
}



# ------------------------------------------------------------------------------------------------------
# Prepare and setup app: SAP Build Process Automation
# ------------------------------------------------------------------------------------------------------
# Entitle subaccount for usage of app  destination SAP Build Process Automation
resource "btp_subaccount_entitlement" "build_process_automation_standard" {
  subaccount_id = module.trialaccount.id
  service_name  = "process-automation-service"
  plan_name     = "standard"
}
# Get serviceplan_id for cicd-service with plan_name "default"
data "btp_subaccount_service_plan" "build_process_automation_standard" {
  subaccount_id =  module.trialaccount.id
  offering_name = "process-automation-service"
  name          = "standard"
  depends_on    = [btp_subaccount_entitlement.build_process_automation_standard]
}
# Create service instance
resource "btp_subaccount_service_instance" "build_process_automation_standard" {
  subaccount_id  = module.trialaccount.id
  serviceplan_id = data.btp_subaccount_service_plan.build_process_automation_standard.id
  name           = "spa-service"
}

# Entitle subaccount for usage of SAP Build Process Automation
resource "btp_subaccount_entitlement" "build_process_automation_free" {
  subaccount_id = module.trialaccount.id
  service_name  = "process-automation"
  plan_name     = "free"
}
# Create app subscription to  SAP Build Process Automation
resource "btp_subaccount_subscription" "build_process_automation_free" {
  subaccount_id = module.trialaccount.id
  app_name      = "process-automation"
  plan_name     = "free"
  depends_on    = [btp_subaccount_entitlement.build_process_automation_free]
}

# ------------------------------------------------------------------------------------------------------
# Assign users to the role collection
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_role_collection_assignment" "ProcessAutomationAdmin" {
  depends_on           = [btp_subaccount_subscription.build_process_automation_free]
  subaccount_id        = module.trialaccount.id
  role_collection_name = "ProcessAutomationAdmin"
  user_name            = var.admin_email
  origin               = var.custom_idp_origin
}

resource "btp_subaccount_role_collection_assignment" "ProcessAutomationDelegate" {
  depends_on           = [btp_subaccount_subscription.build_process_automation_free]
  subaccount_id        = module.trialaccount.id
  role_collection_name = "ProcessAutomationDelegate"
  user_name            = var.admin_email
  origin               = var.custom_idp_origin
}

resource "btp_subaccount_role_collection_assignment" "ProcessAutomationDeveloper" {
  depends_on           = [btp_subaccount_subscription.build_process_automation_free]
  subaccount_id        = module.trialaccount.id
  role_collection_name = "ProcessAutomationDeveloper"
  user_name            = var.admin_email
  origin               = var.custom_idp_origin
}

resource "btp_subaccount_role_collection_assignment" "ProcessAutomationExpert" {
  depends_on           = [btp_subaccount_subscription.build_process_automation_free]
  subaccount_id        = module.trialaccount.id
  role_collection_name = "ProcessAutomationExpert"
  user_name            = var.admin_email
  origin               = var.custom_idp_origin
}

resource "btp_subaccount_role_collection_assignment" "ProcessAutomationParticipant" {
  depends_on           = [btp_subaccount_subscription.build_process_automation_free]
  subaccount_id        = module.trialaccount.id
  role_collection_name = "ProcessAutomationParticipant"
  user_name            = var.admin_email
  origin               = var.custom_idp_origin
}

# ------------------------------------------------------------------------------------------------------
# Create destination for Build Apps & Others
# ------------------------------------------------------------------------------------------------------
# Get plan for destination service
data "btp_subaccount_service_plan" "by_name" {
  subaccount_id = module.trialaccount.id
  name          = "lite"
  offering_name = "destination"
}

# ------------------------------------------------------------------------------------------------------
# Get subaccount data
# ------------------------------------------------------------------------------------------------------
data "btp_subaccount" "subaccount" {
  id = module.trialaccount.id
}

# ------------------------------------------------------------------------------------------------------
# Create the destination
# ------------------------------------------------------------------------------------------------------
resource "btp_subaccount_service_instance" "vcf_destination" {
  subaccount_id  = module.trialaccount.id
  serviceplan_id = data.btp_subaccount_service_plan.by_name.id
  name           = "SAP-Build-Apps-Runtime"
  parameters = jsonencode({
    HTML5Runtime_enabled = true
    init_data = {
      subaccount = {
        existing_destinations_policy = "update"
        destinations = [
          {
            Name                     = "SAP-Build-Apps-Runtime"
            Type                     = "HTTP"
            Description              = "Endpoint to SAP Build Apps runtime"
            URL                      = "https://${data.btp_subaccount.subaccount.subdomain}.cr1.${data.btp_subaccount.subaccount.region}.apps.build.cloud.sap/"
            ProxyType                = "Internet"
            Authentication           = "NoAuthentication"
            "HTML5.ForwardAuthToken" = true
          }
        ]
      }
    }
  })
}

resource "btp_subaccount_service_instance" "CodeJamOrdersService_destination" {
  subaccount_id  = module.trialaccount.id
  serviceplan_id = data.btp_subaccount_service_plan.by_name.id
  name           = "CodeJamOrdersService"
  parameters = jsonencode({
    HTML5Runtime_enabled = true
    init_data = {
      subaccount = {
        existing_destinations_policy = "update"
        destinations = [
          {
            Name                     = "CodeJamOrdersService"
            Type                     = "HTTP"
            Description              = "Endpoint to CodeJam Orders Service"
            URL                      = "https://orderscapapp.cfapps.eu10.hana.ondemand.com/service/OrderManagement"
            ProxyType                = "Internet"
            Authentication           = "NoAuthentication"
            "WebIDEEnabled" = true
            "sap.processautomation.enabled" = true
            "sap.build.usage"= "odata_gen"
            "Appgyver.Enabled" = true
            "sap.applicationdevelopment.actions.enabled" = true
          }
        ]
      }
    }
  })
}


