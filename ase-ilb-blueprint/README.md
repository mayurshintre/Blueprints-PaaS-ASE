# NIST 800-66 Reference PaaS Blueprint Template using ASE

## Contents

- [Solution Overview](#solution-overview)
	- [NIST 800-66 Based Assurance Framework Azure PaaS](#nist-800-66-based-assurance-framework-for-azure-blueprint-deployment)
- [Solution Design and Deployed Resources](#soution-design-and-deployed-resources)
	- [Architecture](#architecture)
	- [Deployed Azure Resources](#deployed-azure-resources)
		- [Virtual Network](#virtual-network)
		- [Application Gateway w/ WAF](#application-gateway---waf)
		- [Redis Cache](#redis-cache)
		- [ILB ASE w/ WebApp](#ilb-ase---web-app)
		- [ILB ASE w/ APIApp](#ilb-ase---api-app)
		- [Azure SQL](#azure-sql)
		- [Azure KeyVault](#keyvault)
	- [Security](###security)
		- [Virtual Network](#virtualnetwork)
		- [Application Gateway w/ WAF](#waf---application-gateway)
		- [Redis Cache](#rediscache)
		- [ILB ASE w/ Web Apps](#ilb-ase-w/-web-apps)
		- [ILB ASE w/ Api Apps](#ilb-ase-w/-api-apps)
		- [Azure SQL](#azuresql)
		- [Azure KeyVault](#azure-keyvault)
- [NIST 800-66 Assurance - Security Compliance Matrix](#nist-800-66-security-matrix-compliance)
- [Deployment Guide](#deployment-and-configuration-activities) 
	- [Prerequisites](#prerequisites)
	- [Configuration Activities](#)
		- [Prefix Value and Tags](#)
		- [Prefix Value and Tags](#)
	- [Deployment Steps](#deployment-process)
- [Cost](#cost)

## Solution Overview

___
**Click [here](#deployment-guide) to jump directly to the deployment guide; However, we highly recommend reading this README in it's entirety**|
___

![alt text](images/sequence.png "Template Deployment Sequence")

The solution deploys a fully automated secure baseline Azure ARM Blueprint to provision a highly secure, orchestrated and configured Platform as a Service environment mapped to a NIST 800-66 assurance security controls matrix, that includes :

+ Azure App Service Environment with an ILB, App Service Environment & Web App
+ Azure App Service Environment with an ILB, App Service Environment & API App
+ Redis Cache Cluster
+ Web Application Gateway with WAF in Prevention Mode
+ Azure SQL 
+ Azure KeyVault

The environment is locked down using Network Security Groups on each subnet with restricted access between all provisioned Azure services and also between subnets, as described in the [security](#security) section below.

### NIST 800-66 Based Assurance Framework for Azure PaaS Blueprint
Lorem epsum.

## Solution Design and Deployed Resources

### Architecture
This diagram displays an overview of the solution

![alt text](images/solution.png "Solution Diagram")

### Deployed Azure Resources

#### 1. Virtual Network
##### Microsoft.Networks
+ **/virtualNetworks**: 1 Virtual Network and 4 Subnets
+ **/publicIPAddresses**: 1 Public IP Address for Application Gateway WAF

#### 2. Application Gateway - WAF
##### Microsoft.Networks
+ **/applicationGateway**: 1 Application Gateway

#### 3. Redis Cache
##### Microsoft.Cache
+ **Redis**: Redis Cache Cluster

#### 4. ILB ASE - Web App
##### Microsoft.Web
+ **/hostingEnvironments**: Deploys App Service Environment v1
+ **/serverFarms**: Deploys a default App Service Plan
+ **kind: "webapp"**: Deploys a default Azure WebApp

#### 5. ILB ASE - API App
##### Microsoft.Web
+ **/hostingEnvironments**: Deploys App Service Environment v1
+ **/serverFarms**: Deploys a default App Service Plan
+ **kind: "apiapp"**: Deploys a default Azure WebApp

#### 6. Azure SQL
##### Microsoft.Sql
+ **/servers**: Deploys an Azure SQL Server
+ **/servers/databases**: Deploys an Azure SQL Database
+ **/servers/firewallRules**: Applied Firewall rule for Outbound IP's from both ASE's

#### 7. Azure KeyVault
##### Microsoft.KeyVault
+ **/vaults**: Deploys a new Keyvault with a secret for Azure SQL

### Security

+ The solution locks down all subnets with a top-level DenyAll with a weight of 100 by default
+ Generates a secure pasword for Azure SQL and stores it as a secret in Azure KeyVault
+ Applies Firewall Roles to lock down incoming traffic to Azure SQL only from provisioned ASE Outbound IP addresses
+ Configures Backend Pools for the Application Gateway to communicate only on Ports 80 and 443 for the ASE ILB IP addresses
+ Blocks all FTP/FTPS 'deployment' access to ASE environments
+ Restricts Azure Redis Cache communication only with the ASE Subnets
+ Turns off non-SSL endpoints for Azure Redis Cache
+ Deploys Application Gateway with WAF turned on in prevention mode with OWASP rulest 3.0

#### Virtual Network

#### WAF - Application Gateway

#### ILB ASE w/ Web Apps

#### ILB ASE w/ Api Apps

#### Redis Cache

#### Azure SQL

#### KeyVault

#### Passwords & Secrets

## NIST 800-66 Security Compliance Matrix

 Security Control| Azure Configuration | Responsibility
  ---|---|---
Control 1 | Mapping | Azure
Control 2 | Mapping | Customer 

## Deployment Guide

### Prerequisites

This solution is built using ARM templates and PowerShell. In order to deploy the solution, you must have the following packages currectly installed and in working order on our machine

+ [Install and configure](https://github.com/PowerShell/PowerShell) the latest version of PowerShell
+ [Install and confgure](https://technet.microsoft.com/en-us/library/dn975125.aspx#Anchor_1) Windows Azure Active Directory Module for Windows PowerShell - Implement Step-1 only
	+_Please Note: The code does **not** use [Azure Active Directory V2 PowerShell module](https://technet.microsoft.com/en-us/library/dn975125.aspx#Anchor_5)_
+ [Install](https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?)Azure Resource Manager PowerShell Module

### Clone the Solution

+ Clone the blueprint to your local machine

``` Batchfile
git clone https://github.com/mayurshintre/Blueprints-PaaS-ASE.git somefolder
``` 
+ or download as a ZIP from https://github.com/mayurshintre/Blueprints-PaaS-ASE

### Deployment Sequence

![alt text](images/sequence.png "Template Deployment Sequence")

## Configuration Values

Please update the following values in the _azuredeploy.parameters.json_ file on your local machine. This file holds all configuration and sizing parameters for all services deployed in this Blueprint. Please follow the instructions carefully as any typo's can result in a failed deployment.

  Resource | Parameter | Default Value| Allowed Values | Configuration
  ---|---|---|---|---|
  All | All | - | **No spaces or special characters. Lower case alphabets and numbers only.** | Adding special characters will break deployment for Azure SQL.
  All | SystemPrefixName | _blueprint_ | lowercase string and numbers, upto 8 characters | Prefix name for the entire solution. Prepended to all resource names. Keep it short (4-6 characters). Lower case alphabets and numbers only. No spaces or special characters.
  Vnet | vnetAddressPrefix | _10.0.0.0_ | Network Space Only | As defined within [RFC 1918 Range](https://tools.ietf.org/html/rfc1918)
  Vnet | vnetAddressPrefixCIDR | _/16_ | CIDR Block | As defined within [RFC 1918 Range](https://tools.ietf.org/html/rfc1918)
  Subnet | WAFSubnetPrefix | _10.0.0.0_ | Within the defined Vnet space | As defined within [RFC 1918 Range](https://tools.ietf.org/html/rfc1918)
  Subnet | WAFSubnetPrefixCIDR | _/24_ | As defined within [RFC 1918 Range](https://tools.ietf.org/html/rfc1918)

## Deployment Steps
At this time you cannot deploy this solution using just the ARM template (azuredeploy.json). The solution is deployed by executing the AzureDeploy.ps1 locally. 

+ Clone the solution on your local machine
+ Navigate to azuredeploy.parameters.json and fill in all parameter values for your deployment as defined in the Configuration Values section
+ Update the User Defined values in the AzureDeploy.ps1
+ Execute AzureDeploy.ps1
+ Grab a beer and wait for deployment to finish. I can take anywhere between 1-2 hours due to ASE.

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
$ParameterFile = "Repository Location\azureDeploy.parameters.json"
    
##Subscription ID that will be used to host the resource group
$SubscriptionID = "Your Subscription ID here"
```
## Modifying the Templates

You can modify the ARM templates directly by following the ARM json syntax. By and large, there should be no need to modify the ARM templates other than the _azuredeploy.parameters.json_ file, except when you wish to 

+ Modify values hardcoded as variables in _azuredeploy.json_ or individual resource templates. For example, if you wish to change the Redis Cache configuration to enable non-SSL ports or change the default cache values, you can navigate to the azuredelploy.json template and modify the following parameters. 
+ Some values are hardcoded as variables in order to prevent the end user from modifying those values to meet NIST 800-66 security controls and in other cases, such as the redis cache _max_ values, because they are widely accepted defaults.

**Please note that, chaning any security related hard-coded variables will break the NIST 800-66 secure baseline compliance assurance provided in the [NIST 800-66 Security Compliance Matrix](#nist-800-66-security-compliance-matrix) section**

``` json
    "enableNonSSLPort": false,

    "redisCachemaxclients": 7500,
    "redisCachemaxmemoryreserved": 200,
    "redisCachemaxfragmentationmemory-reserved": 300,
    "redisCachemaxmemory-delta": 200,
```
_Excerpt from azuredeploy.json for hard-coded redis cache variables not exposed in azuredeploy.parameters.json file_

## Cost

You are entirely responsible for the cost of the Azure services used while running this NIST 800-66 reference PaaS deployment template for ASE. There is no additional cost for using this template. The Azure Resource Manager template for this NIST 800-66 reference PaaS deployment for ASE includes configuration parameters that you can customize. Some of these settings will affect the cost of deployment. For cost estimates, see the pricing pages for each AWS service you will be using or the [Azure Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) or the [Azure Channel Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) if you are an enterprise customer with an ELA. Prices are subject to change.

## Authors

+ Dustin Paulson, Premier Field Engineer, Microsoft
+ Jerad Berhow, Premier Field Engineer, Microsoft
+ Mayur Shintre, Principal Architect, Microsoft

`Tags: [Microsoft, Azure, NIST, 800-66, Compliance, ARM, Templates, PaaS, ASE]`