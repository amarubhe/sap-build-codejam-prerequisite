import { Annotations, TerraformIterator, TerraformStack,Fn } from "cdktf";
//import { Resource as NullResource } from "./.gen/providers/null/resource";
import { Construct } from "constructs";
import { BtpProvider } from "../.gen/providers/btp/provider";
import { CloudfoundryProvider} from "../.gen/providers/cloudfoundry/provider"
import { RandomProvider } from "@cdktf/provider-random/lib/provider";
import { StringResource } from "@cdktf/provider-random/lib/string-resource";
import {Subaccount } from "../.gen/providers/btp/subaccount"
import { DataBtpSubaccountEnvironments } from "../.gen/providers/btp/data-btp-subaccount-environments";
import { DataBtpSubaccount } from "../.gen/providers/btp/data-btp-subaccount";
import { SubaccountEnvironmentInstance } from "../.gen/providers/btp/subaccount-environment-instance";

import { InputEnvConfig } from "../types";
import { log } from "console";

class SubaccountSetupStack extends TerraformStack {
    public readonly newBTPSubaccount: Subaccount;
    public readonly cloudfoundryEnv: SubaccountEnvironmentInstance;

    constructor(scope: Construct, id: string) {
        super(scope, id);
        
        const envConfig =  this.node.getContext("config") as InputEnvConfig

        new BtpProvider(this, "btp", {
            globalaccount: envConfig.btp_global_account_subdomain,
            password: envConfig.btp_admin_password,
            username: envConfig.btp_admin_email,
        })

        new RandomProvider(this,"random")

        const subdomainRandomString = new StringResource(this,"subdomainRandomString",{
            length :8,
            upper : false,
            numeric : true,
            lower : true,
            special : false
        })

        // ------------------------------------------------------------------------------------------------------
        // Create a new subaccount in BTP
        // ------------------------------------------------------------------------------------------------------

        const subaccount_domain  = Fn.lower(envConfig.btp_subaccount_domain || subdomainRandomString.result);
        if(!envConfig.btp_subaccount_domain){
            Annotations.of(this).addInfo("No subaccount domain provided, using random string for subdomain. Please provide a valid subdomain in the environment configuration.");
        }

        this.newBTPSubaccount = new Subaccount(this,"new_subaccount",{
            name : envConfig.btp_subaccount_name,
            subdomain : subaccount_domain,
            region : envConfig.btp_subaccount_region,
            dependsOn : [subdomainRandomString]
        })

        // ------------------------------------------------------------------------------------------------------
        // Fetch all available environments for the subaccount
        // ------------------------------------------------------------------------------------------------------
        const subaccountEnvironments = new DataBtpSubaccountEnvironments(this, "new_subaccount_environments", {
             subaccountId: this.newBTPSubaccount.id, 
             dependsOn: [this.newBTPSubaccount]  
        });

        // ------------------------------------------------------------------------------------------------------
        // Take the landscape label from the first CF environment if no environment label is provided
        // ------------------------------------------------------------------------------------------------------
   
        this.cloudfoundryEnv = new SubaccountEnvironmentInstance(this, "cloudfoundry_env", {
            subaccountId: this.newBTPSubaccount.id,
            name : subaccount_domain,
            environmentType: "cloudfoundry",
            serviceName : "cloudfoundry",
            planName : envConfig.cloudfoundry_service_plan || "trial",
           // landscapeLabel: cfLadscapeLabel,
            parameters : Fn.jsonencode({
                instance_name : subaccount_domain,
                memory : 1024
            }), 
            dependsOn : [this.newBTPSubaccount]
        });
    }
}

export default SubaccountSetupStack;