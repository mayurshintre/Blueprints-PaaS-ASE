![alt text](images/azblueprints.png "Template Deployment Sequence")
# PaaS (ASE) Blueprint with NIST 800-66 Assurance Framework

## Contents

- [1. Solution Overview](#1-solution-overview)
	- [1.1 NIST 800-66 Based Assurance Framework Azure PaaS Blueprint](#11-nist-800-66-based-assurance-framework-for-azure-paas-blueprint)
- [2. Solution Design and Deployed Resources](#2-solution-design-and-deployed-resources)
	- [2.1 Architecture](#21-architecture)
	- [2.2 Deployed Azure Resources](#22-deployed-azure-resources)
		- [Virtual Network](#221-virtual-network)
		- [Application Gateway w/ WAF](#222-application-gateway---waf)
		- [Redis Cache](#223-redis-cache)
		- [ILB ASE w/ Web App](#224-ilb-ase-webapp)
		- [Azure SQL](#225-azure-sql)
		- [Azure KeyVault](#226-azure-keyvault)
	- [2.3 Security](#23-security)
		- [WAF - Application Gateway](#231-waf---application-gateway)
		- [ILB ASE w/ Web Apps](#232-ilb-ase-w-web-apps)
		- [Redis Cache](#233-redis-cache)
		- [Azure SQL](#234-azure-sql)	
		- [Azure KeyVault](#235-keyvault)
- [3. NIST 800-66 Assurance - Security Compliance Matrix](#30-nist-800-66-assurance-security-compliance-matrix)
- [4. Deployment Guide](#4-deployment-guide) 
	- [4.1 Installation Prerequisites](#41-installation-prerequisites)
	- [4.2 Deployment Steps Overview](#42-deployment-steps-overview)
	- [4.3 Template Deployment Sequence](#43-template-deployment-sequence)
	- [4.4 Clone the Solution](#44-clone-the-solution)
	- [4.5 Configure azuredeploy.parameters.json](#45-configure-azuredeployparametersjson)
	- [4.6 Configure azuredeploy.ps1](#46-configure-azuredeployps1-powershell-file)
	- [4.7 Run azuredeploy.ps1](#47-run-azuredeployps1)
	- [4.8 Expected Output](#48-expected-output)
	- [4.9 Optional - Post Deployment ExpressRoute UDR](#49-optional---post-deployment-expressroute-udr)
- [5. Modifying the Templates](#5-modifying-the-templates)
- [6. Cost](#6-cost)

## 1. Solution Overview

![alt text](images/asesequencevsdx.png "Template Deployment Sequence")

This Blueprint deploys a fully automated secure baseline Azure ARM Template + PowerShell solution to provision a highly secure, orchestrated and configured Platform as a Service (PaaS) environment mapped to a NIST 800-66 assurance security controls matrix, that includes :

+ Azure App Service Environment (ASE) with an Internal Load Balancer (ILB)
+ Azure Web App within ASE
+ Redis Cache Cluster
+ Azure Virtual Network
+ Azure Network Security Groups
+ Web Application Gateway with WAF in Prevention Mode
+ Azure SQL 
+ Azure KeyVault
+ Azure Active Directory

The environment is locked down using Network Security Groups on each subnet with restricted access between all provisioned Azure services and also between subnets, as described in the [security](#23-security) section below.

### 1.1 NIST 800-66 Based Assurance Framework for Azure PaaS Blueprint

This Azure refernce Blueprint deployment guide discusses architectural considerations and steps for deploying security-focused baseline environments on Azure. Specifically, this Blueprint deploys a standardized environment that helps organizations with workloads that fall in scope for any of the following:

+ National Institute of Standards and Technology (NIST) SP 800-66 (Revision 4)

## 2. Solution Design and Deployed Resources

### 2.1 Architecture
The diagram below illustrates the deployment topology and architecture of the solution:

![alt text](images/solution.png "Solution Diagram")

### 2.2 Deployed Azure Resources

#### 2.2.1 Virtual Network
##### Microsoft.Networks
+ **/virtualNetworks**: 1 Virtual Network and 3 Subnets
+ **/publicIPAddresses**: 1 Public IP Address for Application Gateway WAF

#### 2.2.2 Application Gateway - WAF
##### Microsoft.Networks
+ **/applicationGateway**: 1 Application Gateway

#### 2.2.3 Redis Cache
##### Microsoft.Cache
+ **/Redis**: Redis Cache Cluster

#### 2.2.4 ILB ASE WebApp
##### Microsoft.Web
+ **/hostingEnvironments**: Deploys App Service Environment **v1**
+ **/serverFarms**: Deploys a default App Service Plan
+ **kind: "webapp"**: Deploys a default Azure WebApp

#### 2.2.5 Azure SQL
##### Microsoft.Sql
+ **/servers**: Deploys an Azure SQL Server
+ **/servers/databases**: Deploys an Azure SQL Database
+ **/servers/firewallRules**: Applied Firewall rule for Outbound IP's from both ASE's

#### 2.2.6 Azure KeyVault
##### Microsoft.KeyVault
+ **/vaults**: Deploys a new Keyvault with a secret for Azure SQL

### 2.3 Security

The solution automatically configures the following security features by default. These configurations are uneditable in the _azuredeploy.parameters.json_ file.

#### 2.3.1 WAF - Application Gateway

+ **WAF**:The solution locks down all subnets with a top-level DenyAll with a weight of 100 by default
+ **WAF**:Deploys Application Gateway with WAF turned on in prevention mode with OWASP rulest 3.0
+ **WAF**:Deploys Application Gateway with WAF turned on to accept incloning requests only on SSL/TLS on Port 443
+ **WAF**:Configures Backend Pools for the Application Gateway to communicate only on Ports 80 and 443 for the ASE ILB IP addresses

#### 2.3.2 ILB ASE w/ Web Apps

+ **ASE**:Configures Inbound Traffic for the ASE Subnet to match requirements listed [here](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-app-service-environment-control-inbound-traffic)
+ **ASE**:Configures Outbound Traffic for the ASE Subnet to match requirements listed [here](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-app-service-environment-network-configuration-expressroute#required-network-connectivity)
+ **ASE**:Blocks all FTP/FTPS 'deployment' access ports to ASE environments
+ **ASE**:Blocks all FTP/FTPS 'deployment' access ports to ASE environments

#### 2.3.3 Redis Cache

+ **Redis Cache**:Restricts Azure Redis Cache communication only with the ASE Subnets
+ **Redis Cache**:Turns off non-SSL endpoints for Azure Redis Cache

#### 2.3.4 Azure SQL

+ **Azure SQL**:Configures Azure SQL to use Transperent Disk Encryption
+ **Azure SQL**:Generates a secure pasword for Azure SQL and stores it as a secret in Azure KeyVault
+ **Azure SQL**:Applies Firewall Roles to lock down incoming traffic to Azure SQL only from provisioned ASE Outbound IP addresses

#### 2.3.5 KeyVault

+ **KV**:Provisions and automatically configures a Vault with a _uniquestring_ password for Azure SQL

#### 2.3.6 Network

+ **Azure VNET**: Provisioned with separate subnet for each individual tier
+ **Azure VNET**: Each Subnet is tightly locked down with Network Security Groups (NSG) to only allow traffic from SSL.TLS endpoints from its corresponding tier
+ **Azure VNET**: All Network Security Group Inbound and Outbound rules are protocol and port speficic
+ **Azure VNET**: All default traffic routing within the VNET (between subnets) is blocked by NSG's unless expicitly defined in the inbound or outbound security rules for each subnet


+ **KV**:Provisions and automatically configures a Vault with a _uniquestring_ password for Azure SQL

## 3.0 NIST 800-66 Assurance Security Compliance Matrix

You can also view the security controls matrix (Microsoft Excel spreadsheet), which maps the architecture decisions, components, and configuration in this Quick Start to security requirements within NIST, TIC, and DoD Cloud SRG publications; indicates which Azure ARM templates and PowerShell scripts affect the controls implementation; and specifies the associated Azure resources within the templates. The excerpt in Figure 1 provides a sample of the available information.

>The NIST 800-66 Security Controls Matrix for this blueprint can be downloaded [here](https://github.com/mayurshintre/Blueprints-PaaS-ASE/tree/master/ase-ilb-blueprint/images/nist80066matrix.xlsx).

![alt text](images/scmexcerpt.png "SCM Excerpt")

## 4. Deployment Guide

### 4.1 Installation Prerequisites

This solution utilizes a combination of ARM templates and PowerShell. In order to deploy the solution, you must have the following packages installed correctly and in working order on your local machine

+ [Install and configure](https://github.com/PowerShell/PowerShell) the latest version of PowerShell
+ [Install and configure](https://technet.microsoft.com/en-us/library/dn975125.aspx#Anchor_5) Azure Active Directory V2 PowerShell Module
+ [Install](https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?) Azure Resource Manager PowerShell Module

### 4.2 Deployment Steps Overview
> **Please Note**: At this time, the entire blueprint cannot be deployed only using the ARM template (azuredeploy.json). The solution must be deployed by executing the AzureDeploy.ps1 locally. 

1. Clone the solution on your local machine
2. Navigate to _azuredeploy.parameters.json_ on your local machine and fill in all parameter values for your deployment as defined in the [Configure _azuredeploy.parameters.json_](#45-configure-azuredeploy.parameters.json) section
3. Update the User Defined values in the AzureDeploy.ps1
4. Execute AzureDeploy.ps1
5. Grab a coffee and wait for deployment to finish. Deployment time can take anywhere between 1-2 hours.

### 4.3 Template Deployment Sequence

![alt text](images/asesequencevsdx.png "Template Deployment Sequence")

### 4.4 Clone the Solution

+ Clone the Blueprint to your local machine

``` Batchfile
git clone https://github.com/mayurshintre/Blueprints-PaaS-ASE.git somefolder
``` 
+ or download as a ZIP from https://github.com/mayurshintre/Blueprints-PaaS-ASE

### 4.5 Configure _azuredeploy.parameters.json_

>This is the **main** configuration file. 

Navigate to the _ase-ilb-blueprint/_ folder file on your local machine and update the default parameters the _azuredeploy.parameters.json_. This file holds all configuration and sizing parameters for all services deployed in this Blueprint. Please follow the instructions carefully as any typo's can result in a failed deployment. Notes for configuration values can be found in this file and also searched in relevant [Azure Quickstart Templates in Github](https://github.com/Azure/azure-quickstart-templates)

### 4.6 Configure _azuredeploy.ps1_ PowerShell File

Set the environment variables user defined inputs section in the _azuredeploy.ps1_ file

``` PowerShell
##Azure Region to Deploy all resources including the Resource Group
$Region = "West US"

##Name of the Resource Group to deploy
$RgName = "demo"
	
##Name to give the Deployment that will be ran
$DeploymentName = $RgName +"nist800ase"

##Location of the main azuredeploy.json template
$TemplateUri = "https://raw.githubusercontent.com/mayurshintre/Blueprints/master/ase-ilb-blueprint/azuredeploy.json"

##Location of the local parameters file
$ParameterFile = "your_local_repository_location\azureDeploy.parameters.json"
    
##Subscription ID that will be used to host the resource group
$SubscriptionID = "Your Subscription ID here"
```
### 4.7 Run _azuredeploy.ps1_

``` PowerShell
Windows PowerShell
Copyright (C)Microsoft Corporation. All rights reserved.

PS C:\User>azuredeploy.ps1

```

### 4.8 Expected Output

``` PowerShell
VERBOSE: Performing the operation "Creating Deployment" on target "BluePrint".
VERBOSE: 9:34:27 PM - Template is valid.
VERBOSE: 9:34:29 PM - Create template deployment 'BluePrint2-nist800ase'
VERBOSE: 9:34:29 PM - Checking deployment status in 5 seconds
VERBOSE: 9:34:36 PM - Resource Microsoft.Resources/deployments 'SQL' provisioning status is running
VERBOSE: 9:34:36 PM - Resource Microsoft.Resources/deployments 'Vnet' provisioning status is running
VERBOSE: 9:34:36 PM - Resource Microsoft.Resources/deployments 'KeyVault' provisioning status is running
VERBOSE: 9:34:36 PM - Checking deployment status in 5 seconds
VERBOSE: 9:34:43 PM - Resource Microsoft.Network/virtualNetworks 'blueprintvnetwxl3ksd4fy5tg' provisioning status is succeeded
VERBOSE: 9:34:43 PM - Resource Microsoft.KeyVault/vaults/secrets 'ILBaseVaultwxl3ksd4fy5tg/SqlSecret' provisioning status is succeeded
VERBOSE: 9:34:43 PM - Resource Microsoft.KeyVault/vaults 'ILBaseVaultwxl3ksd4fy5tg' provisioning status is succeeded
VERBOSE: 9:34:43 PM - Checking deployment status in 5 seconds
VERBOSE: 9:34:50 PM - Resource Microsoft.Resources/deployments 'KeyVault' provisioning status is succeeded
VERBOSE: 9:34:51 PM - Checking deployment status in 5 seconds
VERBOSE: 9:34:59 PM - Resource Microsoft.Resources/deployments 'RedisCachePremium' provisioning status is running
VERBOSE: 9:34:59 PM - Resource Microsoft.Resources/deployments 'AseWeb' provisioning status is running
VERBOSE: 9:34:59 PM - Resource Microsoft.Web/hostingEnvironments 'blueprintasewebwxl3ksd4fy5tg' provisioning status is running
VERBOSE: 9:34:59 PM - Resource Microsoft.Resources/deployments 'Vnet' provisioning status is succeeded
VERBOSE: 9:34:59 PM - Checking deployment status in 5 seconds
...
...
```

### 4.9 Optional - Post Deployment ExpressRoute UDR

If you plan to terminate a VPN connection or On-premises ExpressRoute to this ASE Vnet **and turn on forced tunnelling**, you will require all the subnets to have User Defined Routes to traverse all internet facing traffic direcly out of the Vnet. This is required for proper functioning of the ASE environments as specified in the [ASE ExpressRoute network requirements article](https://docs.microsoft.com/en-us/azure/app-service-web/app-service-app-service-environment-network-configuration-expressroute#enabling-outbound-network-connectivity-for-an-app-service-environment)

The UDR.ps1 script can be run after a successful deployment to apply these default UDR's to all subnets to bypass forced tunneling to on-premises network.

You will require to fill in the following values inside the UDR.ps1 powershell.

``` PowerShell
## Resource Group Name of the deployed Blueprint environment
$ResourceGroup = "RG Name Here"
## Location of the Resource Group of the deployed Blueprint environment
$location = "Location Here"
## Name of the User Defined Route. Can be left at default.
$UDRName = "ASEInternetOutbound"
## Name of the VNET in which the Bluepring ASE is deployed
$ExistingVnetName = "VNet name here"
## Do not rename this variable.
$routeName = "RouteToInternet"
```

## 5. Modifying the Templates

You can modify the ARM templates directly by following the ARM json syntax. By and large, there should be no need to modify the ARM templates except for the _azuredeploy.parameters.json_

In some cases you may wish to modify values hardcoded as variables in _azuredeploy.json_ or individual resource templates under the _/templates_ folder, not exposed as parameters in the _azuredeploy.parameters.json_ template by design. 

+ For example, if you need to change the Redis Cache configuration to enable non-SSL ports, you can navigate to the azuredelploy.json template and modify the following parameters in the json code block below 
``` json
    "enableNonSSLPort": false,
    "redisCachemaxclients": 7500,
    "redisCachemaxmemoryreserved": 200,
    "redisCachemaxfragmentationmemory-reserved": 300,
    "redisCachemaxmemory-delta": 200,
```
_Excerpt from azuredeploy.json for hard-coded redis cache variables not exposed in azuredeploy.parameters.json file_

+ Some values are intentionally hardcoded as variables in _azuredeploy.json_ in order to prevent the end user from modifying those values, to meet the NIST 800-66 security controls, and in other cases, such as the redis cache _max_ values, because they are widely accepted as defaults and do not need end user configuration.

>**Please Note: By changing any security related hard-coded variables in _azuredeploy.json_ or any other individual resource teplates, you will break the NIST 800-66 secure baseline compliance assurance provided in the [NIST 800-66 Security Compliance Matrix](#nist-800-66-security-compliance-matrix) section and the obligation to meet and map any unmet security controls will be transferred on to you, the end user.**

## 6. Cost

You are entirely responsible for the cost of the Azure services used while running this NIST 800-66 reference PaaS deployment template for ASE. There is no additional cost for using this template. The Azure Resource Manager template for this NIST 800-66 reference PaaS deployment for ASE includes configuration parameters that you can customize. Some of these settings will affect the cost of deployment. For cost estimates, see the pricing pages for each AWS service you will be using or the [Azure Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) or the [Azure Channel Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) if you are an enterprise customer with an ELA. Prices are subject to change.

## Authors

+ Mayur Shintre, Principal Architect, Microsoft
+ Jerad Berhow, Premier Field Engineer, Microsoft
+ Dustin Paulson, Premier Field Engineer, Microsoft

`Tags: [Microsoft, Azure, NIST, 800-66, Compliance, ARM, Templates, PaaS, ASE]`