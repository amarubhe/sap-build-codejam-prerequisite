# Build Code CodeJam Pre-requisites

## Overview
This repository contains scripts to automate BTP subaccount setup using Terraform. Please follow the instructions below for initial setup and execution.

---


## 1. Terraform CLI Installation

### Windows
- Download from [Terraform Downloads](https://www.terraform.io/downloads.html).
- Unzip and add the folder to your `PATH`.

### Mac
- Using Homebrew:
    ```sh
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    ```

---

## 1. Environment Variables Setup

### Windows
- Open **Command Prompt** or **PowerShell**.
- Set environment variables as needed (example):
    ```sh
    setx BTP_EMAIL "your-email@example.com"
    setx BTP_PASSWORD "your-password"
    setx BTP_SUBDOMAIN "your-subdomain"
    ```

### Mac
- Open **Terminal**.
- Add to your `~/.bash_profile` or `~/.zshrc`:
    ```sh
    export BTP_EMAIL="your-email@example.com"
    export BTP_PASSWORD="your-password"
    export BTP_SUBDOMAIN="your-subdomain"
    ```
- Run `source ~/.bash_profile` or `source ~/.zshrc`.

---

## 3. Running the Scripts

1. Clone this repository.
2. Update `vars.tfvars` with your BTP email, password, and subdomain.
3. Run the following commands:
     ```sh
     terraform init
     terraform plan -var-file="vars.tfvars"
     terraform apply -var-file="vars.tfvars"
     ```

> **Note:** The script reads credentials from `vars.tfvars` to avoid repeated input.

---

## 4. How to Get Your Subdomain

- Log in to your BTP cockpit.
- Navigate to your subaccount.
- The subdomain is shown in the subaccount overview.




![Subdomain Screenshot](./assets/subdomain_screenshot.png)

---

## 5. Free Tier vs Free Trial Accounts

- For **Free Tier** accounts, update the following variables in `vars.tfvars`:
    - `account_type = "free_tier"`
- For **Free Trial** accounts, use:
    - `account_type = "free_trial"`

---

## 6. Assumptions & Limitations

- Assumes a new BTP Free Trial account (Build Apps not installed).
- Assumes a second subaccount (no Cloud Foundry) already exists.
- User creation is not automated (pending clarification).
- Exception cases (e.g., existing Build Apps, user creation failures) are **not covered**.

---

## 7. Outstanding Questions

- How to automate user creation?
- How to automate subaccount creation (without manual trial account creation)?

---

## 8. Repository Naming

- The repo name has been updated to use "pre-requisites" instead of a hanging "-".

---

## 9. Code Cleanliness

- All commented-out code has been removed for clarity.

---

For further feedback or questions, please contact the repository maintainers.