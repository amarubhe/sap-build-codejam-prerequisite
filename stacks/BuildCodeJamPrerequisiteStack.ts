import {
  Annotations,
  TerraformIterator,
  TerraformStack,
  Fn,
  Token,
} from "cdktf";
//import { Resource as NullResource } from "./.gen/providers/null/resource";
import { Construct } from "constructs";
import { BtpProvider } from "../.gen/providers/btp/provider";
import { CloudfoundryProvider } from "../.gen/providers/cloudfoundry/provider";
import { RandomProvider } from "@cdktf/provider-random/lib/provider";
import { StringResource } from "@cdktf/provider-random/lib/string-resource";
import { Subaccount } from "../.gen/providers/btp/subaccount";
import { DataBtpSubaccountEnvironments } from "../.gen/providers/btp/data-btp-subaccount-environments";
import { DataBtpSubaccount } from "../.gen/providers/btp/data-btp-subaccount";
import { DataBtpSubaccountServicePlan } from "../.gen/providers/btp/data-btp-subaccount-service-plan";
import { SubaccountServiceInstance } from "../.gen/providers/btp/subaccount-service-instance";
import { SubaccountEnvironmentInstance } from "../.gen/providers/btp/subaccount-environment-instance";

import { InputEnvConfig } from "../types";
import { log } from "console";

interface BuildCodeJamPrerequisiteStackProps {
  subaccountDomain: string;
  subaccountRegion: string;
}

class BuildCodeJamPrerequisiteStack extends TerraformStack {
  private subaccountId: string;

  constructor(
    scope: Construct,
    id: string,
    props: BuildCodeJamPrerequisiteStackProps
  ) {
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
    const subaccountDetails = new DataBtpSubaccount(
      this,
      "subaccount_details",
      {
        subdomain: props.subaccountDomain,
        region: props.subaccountRegion,
      }
    );

    this.subaccountId = subaccountDetails.id;

    const destionationLiteServicePlan = new DataBtpSubaccountServicePlan(
      this,
      "by_name",
      {
        name: "lite",
        offeringName: "destination",
        subaccountId: this.subaccountId,
      }
    );

    const buildCodeJamOrderDestionationServiceInstance =
      new SubaccountServiceInstance(
        this,
        "build_codejam_orders_destination_service_instance",
        {
          name: "CodeJamOrdersService",
          serviceplanId: destionationLiteServicePlan.id,
          subaccountId: this.subaccountId,
          dependsOn: [destionationLiteServicePlan],
          parameters: Token.asString(
            Fn.jsonencode({
              HTML5Runtime_enabled: true,
              init_data: {
                subaccount: {
                  destinations: [
                    {
                      "Appgyver.Enabled": true,
                      "sap.applicationdevelopment.actions.enabled": true,
                      "sap.build.usage": "odata_gen",
                      "sap.processautomation.enabled": true,
                      WebIDEEnabled: true,
                      Authentication: "NoAuthentication",
                      Description: "Endpoint to CodeJam Orders Service",
                      Name: "CodeJamOrdersService",
                      ProxyType: "Internet",
                      Type: "HTTP",
                      URL: "https://orderscapapp.cfapps.eu10.hana.ondemand.com/service/OrderManagement",
                    },
                  ],
                  existing_destinations_policy: "update",
                },
              },
            })
          ),
        }
      );
  }
}

export default BuildCodeJamPrerequisiteStack;
