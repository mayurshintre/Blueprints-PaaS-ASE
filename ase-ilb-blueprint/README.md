# NIST 800-66 Assurance PaaS Blueprint for ASE

## Contents

- [Solution Overview](#Overview)
	- NIST Based Assurance Framework Azure PaaS
	- 
- [Architecture Diagram and Deployed Components](#architecture-diagram-and-components)
	- [Deployed Resources]
		- [Resource Provider 1]
		- [Resource Provider 2]
		- [Resource Provider 3]

- [Guidance and Recommendations](#guidance-and-recommendations)
	- [Business continuity](#business-continuity)
	- [Logging and Audit](#logging-and-audit)
	- [Identity](#identity)
	- [Security](#security)

- [NIST Security Compliance Matrix](#ncsc-security-matrix-compliance)

- [Deployment Guide](#deployment-and-configuration-activities) 
	- [Configuration Activities](#)
		- [Prefix Value and Tags](#)
		- [Prefix Value and Tags](#)
	- [Deployment Process](#deployment-process)
	- [PowerShell Deployment](#optional-powershell-deployment)

- [Cost](#cost)

## Solution Overview

This template deploys a NIST 800-66 compliant secure baseline for Azure App service Environment, Web App, API Apps, Redis Cache and Web Application Gateway

### NIST Based Assurance Framework for Azure PaaS

Lorem epsum.

## Solution Architecture and Deployed Resources

This diagram displays an overview of the solution

![alt text](images/solution.png "Solution Diagram")

This deployment uses nested templates.
The following resources are deployed as part of the solution

### Security

#### Network

#### Passwords & Secrets


## Deployed Azure Resources

### [VNET]
[Microsoft.Networks/virtualNetworks]
+ **[Resource type 1A]**: [Description Resource type 1A]
+ **[Resource type 1B]**: [Description Resource type 1B]
+ **[Resource type 1C]**: [Description Resource type 1C]

### [Application Gateway]
[Description Resource Provider 2]
+ **[Resource type 2A]**: [Description Resource type 2A]

### [Redis Cache]
[Description Resource Provider 3]
+ **[Resource type 3A]**: [Description Resource type 3A]
+ **[Resource type 3B]**: [Description Resource type 3B]

### [ILB ASE - Web App]
[Description Resource Provider 3]
+ **[Resource type 3A]**: [Description Resource type 3A]
+ **[Resource type 3B]**: [Description Resource type 3B]

### [ILB ASE - API App]
[Description Resource Provider 3]
+ **[Resource type 3A]**: [Description Resource type 3A]
+ **[Resource type 3B]**: [Description Resource type 3B]

### [Azure SQL]
[Description Resource Provider 3]
+ **[Resource type 3A]**: [Description Resource type 3A]
+ **[Resource type 3B]**: [Description Resource type 3B]

### [Azure KeyVault]
[Description Resource Provider 3]
+ **[Resource type 3A]**: [Description Resource type 3A]
+ **[Resource type 3B]**: [Description Resource type 3B]

## Deployment Guide

### Prerequisites

### Deployment Sequence

![alt text](images/asesequencevsdx.png "Template Deployment Sequence")

## Configuration Values

  Resource| Parameter | Configuration
  ---|---|---
  All | All | **No spaces or special characters. Lower case alphabets and numbers only. Adding special characters will break deployment for Azure SQL.**
  All | Prefix | Prefix name for the entire solution. Prepended to all resource names. Keep it short (4-6 characters). Lower case alphabets and numbers only. No spaces or special characters.

## Deployment steps
You can either click the "deploy to Azure" button at the beginning of this document or deploy the solution from PowerShell with the following PowerShell script.

``` PowerShell
# Login to your subscription
Login-AzureRmAccount

# Variables, replace these with your own values
$ResourceGroupLocation = "West Europe"
$ResourceGroupName = "MyResourceGroup"
$RepositoryPath = "https://raw.githubusercontent.com/marcvaneijk/arm/master/200-nested/200-template/"

# Variables, used for constructing the required values
$TemplateFile = $RepositoryPath + "azuredeploy.json"
$TemplateParameterFile = $RepositoryPath + "azuredeploy.parameters.json"
$DeploymentName = (Get-ChildItem $TemplateFile).BaseName + ((get-date).ToUniversalTime()).ToString('MMddyyyyHHmmss')

# Create new Resource Group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation

# New Resource Group Deployment
New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile
```
## Modifying the Templates

## Usage

#### Connect
[How to connect to the solution]
#### Management
[How to manage the solution]

## Notes
[Solution notes]


## Cost

You are responsible for the cost of the Azure services used while running this NIST 800-66 reference PaaS deployment for ASE. There is no additional cost for using this template. The Azure Resource Manager template for this NIST 800-66 reference PaaS deployment for ASE includes configuration parameters that you can customize. Some of these settings will affect the cost of deployment. For cost estimates, see the pricing pages for each AWS service you will be using or the Azure Calculator. Prices are subject to change.

## Authors

+ Dustin Paulson, Premier Field Engineer, Microsoft
+ Jerad Berhow, Premier Field Engineer, Microsoft
+ Mayur Shintre, Principal Architect, Microsoft

`Tags: [NIST, 800-66, Azure, Templates, PaaS, ASE]`