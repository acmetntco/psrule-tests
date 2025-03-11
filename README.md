# psrule-tests

A simple Azure VM deployment using Bicep templates and GitHub Actions for continuous deployment. This branch will also run [PSRule for Azure](https://github.com/Azure/PSRule.Rules.Azure) across the templated resources to ensure adherance to Azure Well Architected Framework. 

## Overview

This repository contains a Bicep template to deploy an Azure Virtual Machine along with associated resources such as a Network Security Group, Public IP addresses, Virtual Network, Bastion Host, Network Interface, and a Storage Account. The deployment is automated using GitHub Actions.

## PSRule for Azure

[PSRule for Azure](https://github.com/Azure/PSRule.Rules.Azure) is a set of rules to validate Azure resources against best practices and the Azure Well-Architected Framework. It helps ensure that your Azure resources are compliant with recommended practices. The PSRule GitHub Actions workflow runs PSRule for Azure to analyze the Bicep template and ensure it adheres to best practices. This workflow is triggered on every push to the `psrule` branch and can also be manually triggered. It will run PSRule to analyze the Bicep template and generate a report.

The following rules from PSRule for Azure are current set to except with cybersecurity exception SC23459876
  - Azure.VM.UseHybridUseBenefit
  - Azure.VM.Standalone
  - Azure.VM.PublicIPAttached
  - Azure.VM.PublicKey
  - Azure.VM.AMA
  - Azure.VM.MaintenanceConfig
  - Azure.Storage.UseReplication
  - Azure.Storage.SoftDelete
  - Azure.Storage.ContainerSoftDelete

## Resources Deployed

The Bicep template deploys the following resources:

- **Network Security Group** (`Microsoft.Network/networkSecurityGroups`)
- **Public IP Address for VM** (`Microsoft.Network/publicIPAddresses`)
- **Public IP Address for Bastion** (`Microsoft.Network/publicIPAddresses`)
- **Virtual Network** (`Microsoft.Network/virtualNetworks`)
- **Subnets** (`Microsoft.Network/virtualNetworks/subnets`)
- **Bastion Host** (`Microsoft.Network/bastionHosts`)
- **Network Interface** (`Microsoft.Network/networkInterfaces`)
- **Virtual Machine** (`Microsoft.Compute/virtualMachines`)
- **Storage Account** (`Microsoft.Storage/storageAccounts`)
- **Role Assignment** (`Microsoft.Authorization/roleAssignments`)

All resources are deployed with the following attached tags -

- **application**
- **environment**
- **owner**
- **costcenter**

## Prerequisites

- Azure Subscription
- Azure CLI installed
- GitHub repository with the following secrets configured:
  - `AZURE_CLIENT_ID`: Azure service principal client ID
  - `AZURE_TENANT_ID`: Azure service principal tenant ID
  - `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
  - `AZURE_SUBSCRIPTION`: Azure subscription ID (same as `AZURE_SUBSCRIPTION_ID`)
  - `AZURE_RG`: Azure resource group name
  - `AZURE_ADMIN_PASS`: Admin password for the VM

## Deployment

### GitHub Actions

The deployment is automated using GitHub Actions. The workflow file is located at `.github/workflows/deploy.yml`.

#### Workflow Trigger

The workflow is triggered on every push to the `main` branch and can also be manually triggered.

#### Workflow Steps

1. **Checkout repository**: Checks out the repository code.
2. **Log into Azure**: Logs into Azure using the service principal credentials stored in GitHub Secrets.
3. **Deploy Bicep template**: Deploys the Bicep template to the specified Azure resource group.

### Manual Deployment

To manually deploy the Bicep template, use the following Azure CLI command:

```sh
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters adminuser=<your-admin-username> adminpass=<your-admin-password>
```
