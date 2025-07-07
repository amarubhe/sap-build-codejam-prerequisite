import { Fn, TerraformStack } from "cdktf";
import { Construct } from "constructs";
import { Org } from "../.gen/providers/cloudfoundry/org";
import { Space } from "../.gen/providers/cloudfoundry/space";
import { DataCloudfoundryOrg } from "../.gen/providers/cloudfoundry/data-cloudfoundry-org";
import { CloudfoundryProvider } from "../.gen/providers/cloudfoundry/provider";


interface CloudFoundrySetupStackProps {
    cfAPIUrl: string;
    subaccountDomain: string;
}


class CloudFoundrySetupStack extends TerraformStack {
    constructor(scope: Construct, id: string, props: CloudFoundrySetupStackProps) {
        super(scope, id);
        
        const envConfig =  this.node.getContext("config")
        
        new CloudfoundryProvider(this, "cloudfoundry", {
                apiUrl: props.cfAPIUrl,
                user: envConfig.btp_admin_email,
                password: envConfig.btp_admin_password,
        });

        const cfOrgDetails = new DataCloudfoundryOrg(this, "cf_org_details", {
            name: props.subaccountDomain,   
        });
        

        const cfSpace = new Space(this, "cf_space", {
            name: envConfig.cloudfoundry_space,
            org: cfOrgDetails.id,
            dependsOn: [cfOrgDetails]
        })
    }
}

export default CloudFoundrySetupStack;