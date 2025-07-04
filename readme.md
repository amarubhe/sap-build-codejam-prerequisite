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

For further feedback or questions, please contact the repository maintainers.
