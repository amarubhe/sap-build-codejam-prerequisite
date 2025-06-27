# SAP Build CodeJam Pre-requisites:

## Objective
Automate the steps involved in the pre-requisites for [ SAP Build CodeJam ](https://developers.sap.com/tutorials/codejam-0-prerequisites.html)

## Overview
This repository contains scripts to automate BTP subaccount setup using Terraform. Please follow the instructions below for initial setup and execution.

---

## Pre-requisites

Before starting the deployment process, ensure the following:

- You are an **administrator** of the SAP BTP **Global Account**.
- The Global Account has the **required entitlements** assigned (e.g., relevant service plans used in the Terraform scripts).
- The Global Account has sufficient **resource quotas** (e.g., application runtime, service instances).

Note: By Default, these permissions, entitlements, quotas should already be available if this is a fresh BTP Trial account(ie Build Apps is not already subscribed in this BTP global account), so no additional setup is necessary.

---

## 1. Terraform CLI Installation (Local setup)

For information on how to install the Terraform CLI, please refer to the official documentation: [Install Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

---

## 2. Running the Scripts

1. Clone this repository.
2. Rename `sample.tfvars.exmaple` to `sample.tfvars` with your BTP email, password, global account subdomain(Refer Step 3 to get the sub domain name) & subaccount name(can be trial or dev etc).
3. Run the following commands:
     ```sh
     terraform init
     terraform plan -var-file="sample.tfvars"
     terraform apply -var-file="sample.tfvars"
     ```

> **Note:** The script reads credentials from `sample.tfvars` to avoid repeated input for BTP user login.

---

## 3. How to Get Your Subdomain

- Log in to your BTP cockpit.
- Navigate to your BTP global account.
- The global account subdomain is shown in the global account explorer.

![Subdomain Screenshot](./assets/global-account-subdomain.png)


---

## Troubleshooting tips

If you deleted some instances manually from BTP cockpit, the state would be out of sync for terraform, in order to remove **all** the services from the terraform state use the following command in the terminal

`terraform state list | xargs -n1 terraform state rm`

To remove an individual resources, use

`terraform state rm <resource_name>`

for eg: `terraform state rm cloudfoundry_space.space` to delete a cloud foundry resource.

To check the terraform state, use

`terraform state list`

If for some reason, only SAP Build Apps failed to install while running the script, use the below command to install only sap build apps resource

`terraform apply -target=btp_subaccount_entitlement.sap_build_apps -target=btp_subaccount_subscription.sap-build-apps_free`

For further feedback or questions, please contact the repository maintainers.
