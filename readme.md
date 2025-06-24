# Build Code CodeJam Pre-requisites

## Overview
This repository contains scripts to automate BTP subaccount setup using Terraform. Please follow the instructions below for initial setup and execution.

---

## Prerequisites 

Before starting the deployment process, ensure the following:

- You are an **administrator** of the SAP BTP **Global Account**.
- The Global Account has the **required entitlements** assigned (e.g., relevant service plans used in the Terraform scripts).
- The Global Account has sufficient **resource quotas** (e.g., application runtime, service instances).

---

## 1. Terraform CLI Installation

For information on how to install the Terraform CLI, please refer to the official documentation: [Install Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

---

## 2. Running the Scripts

1. Clone this repository.
2. rename `sample.tfvars.exmaple` to `sample.tfvars` with your BTP email, password, global account subdomain & subaccount name.
3. Run the following commands:
     ```sh
     terraform init
     terraform plan -var-file="sample.tfvars"
     terraform apply -var-file="sample.tfvars"
     ```

> **Note:** The script reads credentials from `sample.tfvars` to avoid repeated input.

---

## 3. How to Get Your Subdomain

- Log in to your BTP cockpit.
- Navigate to your btp global account.
- The subdomain is shown in the global account explorer.




![Subdomain Screenshot](./assets/global-account-subdomain.png)


---

For further feedback or questions, please contact the repository maintainers.