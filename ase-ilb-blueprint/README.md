# NIST 800-66 Reference PaaS Blueprint Template using ASE

## Contents

- [Solution Overview](#solution-overview)
	- [NIST 800-66 Based Assurance Framework Azure PaaS](#nist-800-66-based-assurance-framework-for-azure-blueprint-deployment))

- [Solution Design and Deployed Resources](#soution-design-and-deployed-resources)
	- [Architecture](#architecture)
	- [Deployed Azure Resources](#deployed-azure-resources)
		- [Virtual Network & Application Gateway(WAF)](#virtual-network-&-application-gateway(WAF))
		- Microsoft.Cache
		- Microsoft.Web
		- Microsoft.Sql
		- Microsoft.KeyVault
	- [Security](###security)
		- [Virtual Network](#virtualnetwork)
		- [WAF - Application Gateway](#waf---application-gateway)
		- [ILB ASE w/ Web Apps](#ilb-ase-w/-web-apps)
		- [ILB ASE w/ Api Apps](#ilb-ase-w/-api-apps)
		- [Redis Cache](#rediscache)
		- [Azure SQL](#azuresql)
		- [KeyVault](#keyvault)
- [NIST 800-660 Security Compliance Matrix](#nist-800-66-security-matrix-compliance)
- [Deployment Guide](#deployment-and-configuration-activities) 
	- [Configuration Activities](#)
		- [Prefix Value and Tags](#)
		- [Prefix Value and Tags](#)
	- [Deployment Process](#deployment-process)
	- [PowerShell Deployment](#optional-powershell-deployment)

- [Cost](#cost)

## Solution Overview
The solution deploys a fully automated secure baseline Azure ARM Blueprint to provision a highly secure, orchestrated and configured Platform as a Service environment mapped to a NIST 800-66 assurance security controls matrix, that includes :

+ Azure App Service Environment with an ILB, App Service Environment & Web App, 
+ Azure App Service Environment with an ILB, App Service Environment & API App,
+ Redis Cache Cluster
+ Web Application Gateway with WAF in Prevention Mode
+ Azure SQL 
+ Azure KeyVault

The environment is locked down with restricted access and communication between all provisioned Azure services and also between subnets, as described in the security section below.

### NIST 800-66 Based Assurance Framework for Azure PaaS Blueprint Deployment
Lorem epsum.

## Solution Design and Deployed Resources

### Architecture
This diagram displays an overview of the solution

![alt text](images/solution.png "Solution Diagram")

### Deployed Azure Resources

#### 1. Virtual Network & Application Gateway(WAF)
##### Microsoft.Networks
+ **/virtualNetworks**: 1 Virtual Network and 4 Subnets
+ **/publicIPAddresses**: 1 Public IP Address for Application Gateway WAF

#### 2. Application Gateway(WAF)
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
+ **/vaults**: Deploys a Keyvalut with a secret for Azure SQL

### Security

+ The solution locks down all subnets with a top-level DenyAll with a weight of 100 by default
+ Generates a secure pasword for Azure SQL and stores it as a secret in Azure KeyVault
+ Applies Firewall Roles to lock down incoming traffic to Azure SQL only from provisioned ASE Outbound IP addresses
+ Configures Backend Pools for the Application Gateway to communicate only on Ports 80 and 443 for the ASE ILB IP addresses
+ Blocks all FTP/FTPS 'deployment' access to ASE environments
+ Restricts Azure Redis Cache communication only with the ASE Subnets
+ Turns off non-SSL endpoints for Azure Redis Cache

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

This solution is built using ARM templates and PowerShell. In order to deploy the solution, you must have the following packages currectly installed and in working order

+ Latest version of PowerShell 
+ Azure Resource Manager PowerShell Module
+ Azure Storage PowerShell Module
+ Optional - PowerShell ISE

### Deployment Sequence

![alt text](images/sequence.png "Template Deployment Sequence")

1. User Defined Inputs in PowerShell
2. Update the Parameters File (azuredeploy.parameters.json) - 99% of values and decisions are made here
	Define if VNET with Azure DNS or Custom DNS and other values

then

Login to Azure and Azure AD
Then we set context to the correct subscrition specified
then we create resource group if it does not exist
then password is generated for SQL

Then the script calls azuredeploy.json --> will call all other child templates in the following order (check azuredeploy for the order)
we are also giving the SQL password value as a parameter for 

Once everything is spun up then -

the script determines the default domain (i.e. tenant name)
then it gets outputs from the deployment
uses a function to get the internal and OB IP's for the ASE's
Then it defines NSG rules for each subnet and then apploes it for each subnet
then set the SQL firewall rules
and then add the ILB's internal IP's to the back end pool of the apps (overwrites the existing default backendaddresspool)

## Configuration Values

  Resource | Parameter | Default Value| Allowed Values | Configuration
  ---|---|---|---|--_|
  All | All | - | - | **No spaces or special characters. Lower case alphabets and numbers only. Adding special characters will break deployment for Azure SQL.**
  All | SystemPrefixName | blueprint | lowercase string and numbers | Prefix name for the entire solution. Prepended to all resource names. Keep it short (4-6 characters). Lower case alphabets and numbers only. No spaces or special characters.

## Deployment steps
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

## Usage

#### Connect
[How to connect to the solution]
#### Management
[How to manage the solution]

## Cost

You are responsible for the cost of the Azure services used while running this NIST 800-66 reference PaaS deployment template for ASE. There is no additional cost for using this template. The Azure Resource Manager template for this NIST 800-66 reference PaaS deployment for ASE includes configuration parameters that you can customize. Some of these settings will affect the cost of deployment. For cost estimates, see the pricing pages for each AWS service you will be using or the [Azure Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) or the [Azure Channel Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) if you are an enterprise customer with an ELA. Prices are subject to change.

## Authors

+ Dustin Paulson, Premier Field Engineer, Microsoft
+ Jerad Berhow, Premier Field Engineer, Microsoft
+ Mayur Shintre, Principal Architect, Microsoft

`Tags: [Microsoft, Azure, NIST, 800-66, Compliance, ARM, Templates, PaaS, ASE]`