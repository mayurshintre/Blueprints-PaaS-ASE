# NIST 800-66 Assurance PaaS Blueprint for ASE

##Contents

- [Solution Overview](#Overview) 	
- [Architecture Diagram and Deployed Components](#architecture-diagram-and-components)
	- Resource Provider 1
	- Resource Provider 2
	- Resource Provider 3
- [Guidance and Recommendations](#guidance-and-recommendations)
	- [Business continuity](#business-continuity)
	- [Logging and Audit](#logging-and-audit)
	- [Identity](#identity)
	- [Security](#security)
- [NCSC Security Matrix Compliance](#ncsc-security-matrix-compliance)
- [Deployment Guide](#deployment-guide])
- [Deployment and Configuration Activities](#deployment-and-configuration-activities) 
	- [Deployment Process](#deployment-process)
	- [Deploy Networking Infrastructure](#deploy-networking-infrastructure)
	- [Deploy Active Directory Domain](#deploy-active-directory-domain)
	- [Deploy operational workload infrastructure](#deploy-operational-workload-infrastructure)
	- [(Optional) PowerShell Deployment](#optional-powershell-deployment)
- [UK Governments Private Network Connectivity](#uk-governments-private-network-connectivity)
- [Cost](#cost)
- [Further reading](#further-reading)

## Solution Overview

### NIST Based Assurance Framework Azure PaaS

This template deploys a NIST 800-66 compliant secure baseline for Azure App service Environment, Web App, API Apps, Redis Cache and Web Application Gateway 

## Architecture Diagram and Deployed Components

This diagram displays an overview of the solution

![alt text](images/solution.png "diagram")

This deployment uses nested templates.
The following resources are deployed as part of the solution


## Deployed Resources


####[Resource provider 1]
[Description Resource Provider 1]
+ **[Resource type 1A]**: [Description Resource type 1A]
+ **[Resource type 1B]**: [Description Resource type 1B]
+ **[Resource type 1C]**: [Description Resource type 1C]

####[Resource provider 2]
[Description Resource Provider 2]
+ **[Resource type 2A]**: [Description Resource type 2A]

####[Resource provider 3]
[Description Resource Provider 3]
+ **[Resource type 3A]**: [Description Resource type 3A]
+ **[Resource type 3B]**: [Description Resource type 3B]


## Deployment steps
You can either click the "deploy to Azure" button at the beginning of this document or deploy the solution from PowerShell with the following PowerShell script.

### Prerequisites

[Decscription of the prerequistes for the deployment]

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

`Tags: [NIST, 800-66, Azure, Templates, PaaS, ASE]`