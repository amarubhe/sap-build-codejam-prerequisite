import { Fn, TerraformStack, Token } from "cdktf";
import { Construct } from "constructs";
import { BtpProvider } from "../.gen/providers/btp/provider";
import { SubaccountEntitlement } from "../.gen/providers/btp/subaccount-entitlement";
import { DataBtpSubaccount } from "../.gen/providers/btp/data-btp-subaccount";
import { SubaccountServiceInstance } from "../.gen/providers/btp/subaccount-service-instance";
import { DataBtpSubaccountServicePlan } from "../.gen/providers/btp/data-btp-subaccount-service-plan";
import { DataBtpSubaccountRoles } from "../.gen/providers/btp/data-btp-subaccount-roles";
import {
  SubaccountRoleCollection,
  SubaccountRoleCollectionRoles,
} from "../.gen/providers/btp/subaccount-role-collection";
import { SubaccountRoleCollectionAssignment } from "../.gen/providers/btp/subaccount-role-collection-assignment";
import { SubaccountSubscription } from "../.gen/providers/btp/subaccount-subscription";
import { SubaccountTrustConfiguration } from "../.gen/providers/btp/subaccount-trust-configuration";

interface BuildCodeBoosterStackProps {
  subaccountDomain: string;
  subaccountRegion: string;
}

class BuildCodeBoosterStack extends TerraformStack {
  private subaccountId: string;  
  public readonly idpSubscrption: SubaccountSubscription;
  constructor(scope: Construct, id: string, props: BuildCodeBoosterStackProps) {
    super(scope, id);

    const envConfig = this.node.getContext("config");

    new BtpProvider(this, "btp", {
      globalaccount: envConfig.btp_global_account_subdomain,
      password: envConfig.btp_admin_password,
      username: envConfig.btp_admin_email,
    });

    // ------------------------------------------------------------------------------------------------------
    // Fetch Subaccount Details
    // ------------------------------------------------------------------------------------------------------
    const subaccountDetails = new DataBtpSubaccount(this, "subaccount_details", {
      subdomain: props.subaccountDomain,
      region: props.subaccountRegion,
    });

    this.subaccountId = subaccountDetails.id;


    // ------------------------------------------------------------------------------------------------------
    // Create Custom Identity Provider & Setup Trust Configuration
    // ------------------------------------------------------------------------------------------------------

    //1. Setup Identity Provider Trust Configuration

    const sapIdentityServicesOnboarding = new SubaccountEntitlement(
      this,
      "entitlement-sap-identity-services",
      {
        planName: "default",
        serviceName: "sap-identity-services-onboarding",
        subaccountId: this.subaccountId,
      }
    );

    const subscriptionSapIdentityServicesOnboarding =
      new SubaccountSubscription(this, "subsription-sap-identity-services", {
        appName: "sap-identity-services-onboarding",
        dependsOn: [sapIdentityServicesOnboarding],
        planName: "default",
        subaccountId: this.subaccountId,
      });

    this.idpSubscrption = subscriptionSapIdentityServicesOnboarding;

    //2. Setup Identity Provider Trust Configuration
    const trustConfig = new SubaccountTrustConfiguration(
      this,
      "trust_configuartion",
      {
        dependsOn: [subscriptionSapIdentityServicesOnboarding],
        identityProvider: Token.asString(
          Fn.trimsuffix(
            Token.asString(
              Fn.trimprefix(this.idpSubscrption.subscriptionUrl, "https://")
            ),
            "/admin"
          )
        ),
        subaccountId: this.subaccountId,
      }
    );

    // ------------------------------------------------------------------------------------------------------
    // Prepare and setup app: SAP Build Apps
    // ------------------------------------------------------------------------------------------------------

    const entitlementBuildAppsFree = new SubaccountEntitlement(
      this,
      "entitlement-build-apps-free",
      {
        planName: "free",
        serviceName: "sap-build-apps",
        subaccountId: this.subaccountId,
        amount: 1,
      }
    );

    const subscriptionSapBuildAppsFree = new SubaccountSubscription(
      this,
      "sap-build-apps_free",
      {
        appName: "sap-appgyver-ee",
        dependsOn: [trustConfig,entitlementBuildAppsFree],
        planName: "free",
        subaccountId: this.subaccountId,
        timeouts: {
          create: "20m",
          delete: "20m",
        },
      }
    );

    // ------------------------------------------------------------------------------------------------------
    // Get all roles in the subaccount
    // ------------------------------------------------------------------------------------------------------
    const allSubaccountRoles = new DataBtpSubaccountRoles(
      this,
      "btp-subaccount-roles",
      {
        dependsOn: [subscriptionSapBuildAppsFree],
        subaccountId: this.subaccountId,
      }
    );

    // ------------------------------------------------------------------------------------------------------
    // Setup for role collection BuildAppsAdmin
    // ------------------------------------------------------------------------------------------------------
    const createRoleCollectionBuildAppsAdmin = new SubaccountRoleCollection(
      this,
      "create_role_collection_build_apps_admin",
      {
        subaccountId:this.subaccountId,
        
        name: "BuildAppsAdmin",
        description: "Role Collection for SAP Build Apps Admin",
        dependsOn : [allSubaccountRoles],
        roles: Fn.tolist(allSubaccountRoles.values)
          .filter((role: any) => {
            console.log(role);
            return role.name?.startsWith("BuildAppsAdmin");
          })
          .map((role: any) => {
            return {
              name: role.name,
              roleTemplateAppId: role.appId,
              roleTemplateName: role.roleTemplateName,
            } as SubaccountRoleCollectionRoles;
          }),
      }
    );

    const roleCollectionAssignmentBuildAppsBuildAppsAdmin =
      new SubaccountRoleCollectionAssignment(
        this,
        "assignment_role_collection_build_apps_admin",
        {
          dependsOn: [createRoleCollectionBuildAppsAdmin],
          origin: envConfig.idp_origin,
          roleCollectionName: "BuildAppsAdmin",
          subaccountId:this.subaccountId,
          userName: envConfig.btp_admin_email,
        }
      );

    // ------------------------------------------------------------------------------------------------------
    // Setup for role collection BuildAppsDeveloper
    // ------------------------------------------------------------------------------------------------------
    const createRoleCollectionBuildAppsDeveloper = new SubaccountRoleCollection(
      this,
      "create_role_collection_build_apps_developer",
      {
        subaccountId: this.subaccountId,
        name: "BuildAppsDeveloper",
        description: "Role Collection for SAP Build Apps Developer",
        dependsOn : [allSubaccountRoles],
        roles: Fn.tolist(allSubaccountRoles.values)
          .filter((role: any) => {
            console.log(role);
            return role.name?.startsWith("BuildAppsDeveloper");
          })
          .map((role: any) => {
            return {
              name: role.name,
              roleTemplateAppId: role.appId,
              roleTemplateName: role.roleTemplateName,
            } as SubaccountRoleCollectionRoles;
          }),
      }
    );

    const roleCollectionAssignmentBuildAppsBuildAppsDeveloper =
      new SubaccountRoleCollectionAssignment(
        this,
        "assignment_role_collection_build_apps_developer",
        {
          dependsOn: [createRoleCollectionBuildAppsDeveloper],
          origin: envConfig.idp_origin,
          roleCollectionName: "BuildAppsDeveloper",
          subaccountId: this.subaccountId,
          userName: envConfig.btp_admin_email,
        }
      );

    // ------------------------------------------------------------------------------------------------------
    // Prepare and setup app: SAP Build Workzone, standard edition
    // ------------------------------------------------------------------------------------------------------
    const entitlementBuildWorkzone = new SubaccountEntitlement(
      this,
      "entitlement_build_workzone",
      {
        planName: "standard",
        serviceName: "SAPLaunchpad",
        subaccountId: this.subaccountId,
      }
    );

    const subscriptionBuildWorkzone = new SubaccountSubscription(
      this,
      "subscription_build_workzone",
      {
        appName: "SAPLaunchpad",
        dependsOn: [entitlementBuildWorkzone, trustConfig],
        planName: "standard",
        subaccountId: this.subaccountId,
      }
    );

    new SubaccountRoleCollectionAssignment(
      this,
      "assignment_role_collection_launchpad_admin",
      {
        dependsOn: [subscriptionBuildWorkzone],
        origin: envConfig.idp_origin,
        roleCollectionName: "Launchpad_Admin",
        subaccountId: this.subaccountId,
        userName: envConfig.btp_admin_email,
      }
    );

    // ------------------------------------------------------------------------------------------------------
    // Prepare and setup app: SAP Build Process Automation, standard edition
    // ------------------------------------------------------------------------------------------------------

    const entitlementBuildProcessAutomationStandard = new SubaccountEntitlement(
      this,
      "entitlement_build_process_automation_standard",
      {
        planName: "standard",
        serviceName: "process-automation-service",
        subaccountId: this.subaccountId,
      }
    );

    //# Get serviceplan_id for build-service with plan_name "default"
    const buildProcessAutomationStandardServicePlan =
      new DataBtpSubaccountServicePlan(
        this,
        "build_process_automation_standard_service_plan",
        {
          subaccountId: this.subaccountId,
          offeringName: "process-automation-service",
          name: "standard",
          dependsOn: [entitlementBuildProcessAutomationStandard],
        }
      );

    const btpSubaccountServiceInstanceBuildProcessAutomationStandard =
      new SubaccountServiceInstance(
        this,
        "build_process_automation_standard_service_instance",
        {
          name: "spa-service",
          serviceplanId: buildProcessAutomationStandardServicePlan.id,
          subaccountId: this.subaccountId,
        }
      );

    //  Entitle subaccount for usage of SAP Build Process Automation Free
    const entitlementBuildProcessAutomationFree = new SubaccountEntitlement(
      this,
      "entitlement_build_process_automation_free",
      {
        planName: "free",
        serviceName: "process-automation",
        subaccountId:this.subaccountId,
      }
    );
    // Create subscription for SAP Build Process Automation Free
    const subscriptionBuildProcessAutomationFree = new SubaccountSubscription(
      this,"subscription_build_process_automation_free",
      {
        appName: "process-automation",
        dependsOn: [entitlementBuildProcessAutomationFree,trustConfig],
        planName: "free",
        subaccountId: this.subaccountId,
        timeouts: {
          create: "20m",
          delete: "20m",
        },
      });

    // Assign role collection BuildProcessAutomationAdmin to the BTP Admin user
    new SubaccountRoleCollectionAssignment(
      this,
      "assignment_role_collection_build_process_automation_admin",
      {
        dependsOn: [subscriptionBuildProcessAutomationFree],
        origin: envConfig.idp_origin,
        roleCollectionName: "ProcessAutomationAdmin",
        subaccountId: this.subaccountId,
        userName: envConfig.btp_admin_email,
      }
    );

    new SubaccountRoleCollectionAssignment(
      this,
      "assignment_role_collection_build_process_automation_delegate",
      {
        dependsOn: [subscriptionBuildProcessAutomationFree],
        origin: envConfig.idp_origin,
        roleCollectionName: "ProcessAutomationDelegate",
        subaccountId: this.subaccountId,
        userName: envConfig.btp_admin_email,
      }
    );

    new SubaccountRoleCollectionAssignment(
      this,
      "assignment_role_collection_build_process_automation_developer",
      {
        dependsOn: [subscriptionBuildProcessAutomationFree],
        origin: envConfig.idp_origin,
        roleCollectionName: "ProcessAutomationDeveloper",
        subaccountId: this.subaccountId,
        userName: envConfig.btp_admin_email,
      }
    );


    new SubaccountRoleCollectionAssignment(
      this,
      "assignment_role_collection_build_process_automation_expert",
      {
        dependsOn: [subscriptionBuildProcessAutomationFree],
        origin: envConfig.idp_origin,
        roleCollectionName: "ProcessAutomationExpert",
        subaccountId: this.subaccountId,
        userName: envConfig.btp_admin_email,
      }
    );

    new SubaccountRoleCollectionAssignment(
      this,
      "assignment_role_collection_build_process_automation_participant",
      {
        dependsOn: [subscriptionBuildProcessAutomationFree],
        origin: envConfig.idp_origin,
        roleCollectionName: "ProcessAutomationParticipant",
        subaccountId: this.subaccountId,
        userName: envConfig.btp_admin_email,
      }
    );

    const destionationLiteServicePlan = new DataBtpSubaccountServicePlan(this, "by_name", {
      name: "lite",
      offeringName: "destination",
      subaccountId: this.subaccountId,
    });

    const buildAppRuntimeDestinationServiceInstance = new SubaccountServiceInstance(
      this,
      "build_app_runtime_destination_service_instance",
      {
        name: "SAP-Build-Apps-Runtime",
        serviceplanId: destionationLiteServicePlan.id,
        subaccountId: this.subaccountId,
        dependsOn : [destionationLiteServicePlan],
        parameters : Token.asString(
        Fn.jsonencode({
          HTML5Runtime_enabled: true,
          init_data: {
            subaccount: {
              destinations: [
                {
                  "HTML5.ForwardAuthToken": true,
                  Authentication: "NoAuthentication",
                  Description: "Endpoint to SAP Build Apps runtime",
                  Name: "SAP-Build-Apps-Runtime",
                  ProxyType: "Internet",
                  Type: "HTTP",
                  URL: `https://${props.subaccountDomain}.${props.subaccountRegion}.apps.sap.hana.ondemand.com`,
                },
              ],
              existing_destinations_policy: "update",
            },
          },
        })
      )}
    );


  }
}

export default BuildCodeBoosterStack;
