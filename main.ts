import { Construct } from "constructs";
import { App, Fn, TerraformStack, TerraformVariable, VariableType } from "cdktf";
import { BtpProvider } from "./.gen/providers/btp/provider";

import * as dotenv from "dotenv";
import * as dotenvExt from  "dotenv-extended"
import SubaccountSetupStack from "./stacks/SubaccountSetupStack";
import CloudFoundrySetupStack from "./stacks/CloudFoundrySetupStack";
import { InputEnvConfig } from "./types";
import { log } from "console";
import BuildCodeBoosterStack from "./stacks/BuildCodeBoosterStack";
import BuildCodeJamPrerequisiteStack from "./stacks/BuildCodeJamPrerequisiteStack";

// Load environment variables from .env file
const envConfig = dotenvExt.load ()
log("Environment Configuration Loaded: ", envConfig);
const app = new App({
  context : { config :  envConfig as InputEnvConfig }
});

if(envConfig.use_existing_subaccount === "false") {
  const subaccountStack = new SubaccountSetupStack(app, "subaccount_setup" );
  log("Subaccount Setup Created: ", subaccountStack.newBTPSubaccount.id);
  new CloudFoundrySetupStack(app, "cloud_foundry_setup", {
    cfAPIUrl: Fn.lookup(Fn.jsondecode(subaccountStack.cloudfoundryEnv.labels),"API Endpoint"),
    subaccountDomain: subaccountStack.newBTPSubaccount.subdomain,
  });
  new BuildCodeBoosterStack(app, "build_code_booster", {
    subaccountDomain: subaccountStack.newBTPSubaccount.subdomain,
    subaccountRegion: subaccountStack.newBTPSubaccount.region,
  });
  new BuildCodeJamPrerequisiteStack(app, "build_code_jam_prerequisite", {
    subaccountDomain: subaccountStack.newBTPSubaccount.subdomain,
    subaccountRegion: subaccountStack.newBTPSubaccount.region,
  });
}else{
  log("Using existing subaccount, skipping subaccount and cloud foundry setup.");
  new BuildCodeBoosterStack(app, "build_code_booster", {
    subaccountDomain: envConfig.btp_subaccount_domain,
    subaccountRegion: envConfig.btp_subaccount_region
  });
  new BuildCodeJamPrerequisiteStack(app, "build_code_jam_prerequisite", {
    subaccountDomain: envConfig.btp_subaccount_domain,
    subaccountRegion: envConfig.btp_subaccount_region
  });
}

app.synth();
