# NIST 800-66 Blueprint for ILB ASE

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https://github.com/mayurshintre/Blueprints/blob/master/ase-ilb-blueprint/azuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/></a>

This template deploys a NIST 800-66 compliant secure baseline for Azure App service Environment, Web App, API Apps, Redis Cache and Web Application Gateway 

`Tags: [Tag1, Tag2, Tag3]`

## Solution diagram and deployed resources

This diagram displays an overview of the solution

![alt text](images/diagram.png "diagram")

This deployment uses nested templates.
The following resources are deployed as part of the solution

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

## Prerequisites

[Decscription of the prerequistes for the deployment]

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

## Usage
#### Connect
[How to connect to the solution]
#### Management
[How to manage the solution]

## Notes
[Solution notes]
