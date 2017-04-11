###########################
###ILB-ASE Deploy Script###
###Version: 1.0         ###  
###Author: Jerad Berhow####
###########################

#Parameters Region
#region
    ##Azure Region to Deploy all resources including the Resource Group
    $Region = "West US"
    ##Name of the Resource Group to deploy
    $RgName = "rgJohnCena"
    ##Name to give the Deployment that will be ran
    $DeploymentName = $RgName +"Nist800-66Deployment"
    ##Location of the main azuredeploy.json template
    $TemplateUri = "https://raw.githubusercontent.com/mayurshintre/Blueprints/master/ase-ilb-blueprint/azuredeploy.json"
    ##Location of the local parameters file
    $ParameterFile = "C:\Temp\azureDeploy.Parameters.json"
    ##Subscription ID that will be used to host the resource group
    $SubscriptionID = "960e1588-d82e-47d5-8c2c-342cd071e172"
#endregion


Write-Host "=> Hey there..."
Write-Host "=> I am ARMDLE the Azure Resource Manager Deployment Logistics Expert..."
Write-Host "=> Let us get this party started..."
Write-Host "=> ..."
Write-Host "=> ...."
Write-Host "=> ....."
Write-Host "=> ......"
Write-Host "=> First up! Login to ARM if you are not already..."

##Catch to verify AzureRM session is active.  Forces sign-in if no session is found
#region
    Write-Output "=> Signing into Azure."
    do {
        $azureAccess = $true
	    Try {
		    Get-AzureRmSubscription -ErrorAction Stop | Out-Null
    	}
	    Catch {
            Write-Output "=> Guess you should have logged in already huh?"
		    $azureAccess = $false
		    Login-AzureRmAccount -ErrorAction SilentlyContinue | Out-Null
	    }
    } while (! $azureAccess)
    Write-Host "=> You are now Logged into Azure Resource Manager."
#endregion

##Catch to verify AzureAD session is active.  Forces sign-in if no session is found
#region
    Write-Output "=> Signing into Azure AD."
    do {
        $azureAccess = $true
	    Try {
		    Get-MsolAccountSku -ErrorAction Stop | Out-Null
    	}
	    Catch {
            Write-Output "=> Guess you should have logged in already huh?"
		    $azureAccess = $false
		    Connect-MsolService -ErrorAction SilentlyContinue | Out-Null
	    }
    } while (! $azureAccess)
    Write-Host "=> You are now Logged into Azure Resource Manager."
#endregion


##Set Azure Context
Write-Host "=> I suggest you ask Mayur to fetch the coffee while I set your context..."
Set-AzureRmContext -SubscriptionId $SubscriptionID
Write-Host "=> Context is now set to Subscription $SubscriptionID"

# Checking for network resource group, creating if does not exist
Write-Host "=> Time to make sure the grmelins have not eaten your Resource Group already..."
if (!(Get-AzureRMResourceGroup -Name $RgName -ErrorAction SilentlyContinue))
{
    Write-Host "=> Oh No!  They ate it...."
    Write-Host "=> I got this though... Making a new one for you!"
    New-AzureRmResourceGroup -Name $RgName -Location $Region

}
Write-Host "=> Resource Group $RgName now exists!"

## Deploying the Template
Write-Host "=> Booting up the Matrix so I can deploy some Nist Compliant Architecture now..."
Write-Host "=> Here we go...."
New-AzureRMResourceGroupDeployment -Name $DeploymentName `
    -ResourceGroupName $RgName `
    -TemplateUri $TemplateUri `
    -TemplateParameterFile $ParameterFile `
    -Mode Incremental `
    -Verbose
Write-Host "=> Man that was tense... Good thing we know some Kung-Fu or those fraggles might have been the end of the road..."

##Get Azure AD Tenant Name
$Domains = Get-MsolDomain
foreach($Domain in $Domains)
{
    if($Domain.IsInitial)
    {
        $aadtenant = $Domain.Name
    }
}

##Get Outputs from Deployment
$AseName = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $RgName -Name $DeploymentName).Outputs.AseName.Value
$VnetName = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $RgName -Name $DeploymentName).Outputs.VnetName.Value
$SqlName = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $RgName -Name $DeploymentName).Outputs.SqlName.Value

$resourceID = (Get-AzureRmResource | where -Property resourcename -EQ $AseName).resourceID

function GetAuthToken
 {
    param
    (
         [Parameter(Mandatory=$true)]
         $ApiEndpointUri,
         
         [Parameter(Mandatory=$true)]
         $AADTenant
    )
  
    $adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\" + `
             "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\" + `
                 "Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
    
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    
    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $authorityUri = “https://login.windows.net/$aadTenant”
    
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authorityUri
    
    $authResult = $authContext.AcquireToken($ApiEndpointUri, $clientId,$redirectUri, "Auto")
  
    return $authResult
 } 

$ApiEndpointUri = "https://management.core.windows.net/"

$token = GetAuthToken -ApiEndPointUri $ApiEndpointUri -AADTenant $aadtenant

$header = @{
    'Content-Type'='application\json'
    'Authorization'=$token.CreateAuthorizationHeader()
}

$uri = "https://management.azure.com$resourceID/capacities/virtualip?api-version=2015-08-01"

$hostingInfo = Invoke-RestMethod -Uri $uri -Headers $header -Method get
$hostingInfo.internalIpAddress
$hostingInfo.outboundIpAddresses

##WAF Rules
#region
  $WAFRule1 = New-AzureRmNetworkSecurityRuleConfig -Name DenyAllInbound -Description "Deny All Inbound" `
 -Access Allow -Protocol * -Direction Inbound -Priority 300 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
 -DestinationPortRange *

  $WAFRule2 = New-AzureRmNetworkSecurityRuleConfig -Name HTTPS-In -Description "Allow Inbound HTTPS" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 `
 -SourceAddressPrefix Internet -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 443

  $WAFRule3 = New-AzureRmNetworkSecurityRuleConfig -Name HTTP-In -Description "Allow Inbound HTTP" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 120 `
 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * `
 -DestinationPortRange 80
 
  $WAFRule4 = New-AzureRmNetworkSecurityRuleConfig -Name ILBWebAppHTTP-In -Description "Allow Inbound ILBWebAppHTTP" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 130 `
 -SourceAddressPrefix $hostingInfo.internalIpAddress -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 80

   $WAFRule5 = New-AzureRmNetworkSecurityRuleConfig -Name ILBWebAppHTTPS-In -Description "Allow Inbound ILBWebAppHTTPS" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 140 `
 -SourceAddressPrefix $hostingInfo.internalIpAddress -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 443

   $WAFRule6 = New-AzureRmNetworkSecurityRuleConfig -Name DNS-In -Description "Allow Inbound DNS" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 150 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 53

  $WAFRule7 = New-AzureRmNetworkSecurityRuleConfig -Name DenyAllOutbound -Description "Deny All Outbound" `
 -Access Allow -Protocol * -Direction Outbound -Priority 300 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
 -DestinationPortRange *

  $WAFRule8 = New-AzureRmNetworkSecurityRuleConfig -Name HTTPS-Out -Description "Allow Outbound HTTPS" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 110 `
 -SourceAddressPrefix Internet -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 443

  $WAFRule9 = New-AzureRmNetworkSecurityRuleConfig -Name HTTP-Out -Description "Allow Outbound HTTP" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 120 `
 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * `
 -DestinationPortRange 80
 
  $WAFRule10 = New-AzureRmNetworkSecurityRuleConfig -Name ILBWebAppHTTP-Out -Description "Allow Outbound ILBWebAppHTTP" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 130 `
 -SourceAddressPrefix $hostingInfo.internalIpAddress -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 80

   $WAFRule11 = New-AzureRmNetworkSecurityRuleConfig -Name ILBWebAppHTTPS-Out -Description "Allow Outbound ILBWebAppHTTPS" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 140 `
 -SourceAddressPrefix $hostingInfo.internalIpAddress -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 443

   $WAFRule12 = New-AzureRmNetworkSecurityRuleConfig -Name DNS-Out -Description "Allow Outbound DNS" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 150 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 53
 #endregion

##ASE Rules
#region
  $ASERule1 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowInboundASEManagement -Description "Allows All Inbound ASE Management" `
 -Access Allow -Protocol * -Direction Inbound -Priority 100 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
 -DestinationPortRange 454-455

  $ASERule2 = New-AzureRmNetworkSecurityRuleConfig -Name VnetAllowInboundHTTPS -Description "Allow Inbound HTTPS" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 300 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 443

  $ASERule3 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowOutboundASEManagement -Description "Allow Outbound ASE Management" `
 -Access Allow -Protocol * -Direction Outbound -Priority 100 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
 -DestinationPortRange 445
 
  $ASERule4 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowOutboundDNS -Description "Allow Outbound DNS" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 200 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 53

   $ASERule5 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowOutboundHTTP -Description "Allow Outbound HTTP" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 300 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 80

   $ASERule6 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowOutboundHTTPS -Description "Allow Outbound HTTPS" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 400 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 443

  $ASERule7 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowSQL1 -Description "Allow SQL Connectivity" `
 -Access Allow -Protocol * -Direction Outbound -Priority 510 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
 -DestinationPortRange 1433

  $ASERule8 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowSQL2 -Description "Allow ports for ADO.NET 4.5 client interactions" `
 -Access Allow -Protocol * -Direction Outbound -Priority 500 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 11000-11999

  $ASERule9 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowSQL3 -Description "Allow ports for ADO.NET 4.5 client interactions" `
 -Access Allow -Protocol * -Direction Outbound -Priority 520 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
 -DestinationPortRange 14000-14999
 
  $ASERule10 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowInboundHTTP -Description "Allow Inbound HTTP" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 80

   $ASERule11 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowInboundVS1 -Description "Allow Inbound Visual Studio 2012 Debugging" `
 -Access Allow -Protocol * -Direction Inbound -Priority 400 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 4016

   $ASERule12 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowInboundVS2 -Description "Allow Inbound Visual Studio 2013 Debugging" `
 -Access Allow -Protocol * -Direction Inbound -Priority 500 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 4018

   $ASERule13 = New-AzureRmNetworkSecurityRuleConfig -Name AllAllowInboundVS3 -Description "Allow Inbound Visual Studio 2015 Debugging" `
 -Access Allow -Protocol * -Direction Inbound -Priority 600 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 4020
 #endregion

##Redis Rules
#region
  $RedisRule1 = New-AzureRmNetworkSecurityRuleConfig -Name AllowHTTP -Description "Redis dependencies on Azure Storage/PKI (Internet)" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
 -DestinationPortRange 80

  $RedisRule2 = New-AzureRmNetworkSecurityRuleConfig -Name AllowInboundHTTPS -Description "Allow Inbound HTTPS" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 200 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix * -DestinationPortRange 443

  $RedisRule3 = New-AzureRmNetworkSecurityRuleConfig -Name AllowDNS -Description "Allow DNS Outbound" `
 -Access Allow -Protocol * -Direction Outbound -Priority 300 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
 -DestinationPortRange 445
 
  $RedisRule4 = New-AzureRmNetworkSecurityRuleConfig -Name AllowRedisClientCommunication -Description "Allow Client communication to Redis" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 400 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 6379

  $RedisRule5 = New-AzureRmNetworkSecurityRuleConfig -Name  AllowAzureLoadBalancing -Description "Allow Azure Load Balancing" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 500 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix AzureLoadBalancer -DestinationPortRange 6380

  $RedisRule6 = New-AzureRmNetworkSecurityRuleConfig -Name ImplementationDetail-out -Description "Outbound Implementation Detail for Redis" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 600 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 8443

  $RedisRule7 = New-AzureRmNetworkSecurityRuleConfig -Name ImplementationDetail-in -Description "Inbound Implementation Detail for Redis" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 700 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 8443
 
  $RedisRule8 = New-AzureRmNetworkSecurityRuleConfig -Name AzureLoadBalancing -Description "Allow Azure Load Balancing" `
 -Access Allow -Protocol * -Direction Inbound -Priority 800 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix AzureLoadBalancer `
 -DestinationPortRange 8500

  $RedisRule9 = New-AzureRmNetworkSecurityRuleConfig -Name OutRestrictImplementationDetailVnet -Description "Implementation Detail for Redis (can restrict remote endpoint to VIRTUAL_NETWORK)" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 900 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 10221-10231

  $RedisRule10 = New-AzureRmNetworkSecurityRuleConfig -Name OutRestrictImplementationDetailLB -Description "Implementation Detail for Redis (can restrict remote endpoint to VIRTUAL_NETWORK)" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 1000 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix AzureLoadBalancer -DestinationPortRange 10221-10231

  $RedisRule11 = New-AzureRmNetworkSecurityRuleConfig -Name InRestrictImplementationDetailVnet -Description "Implementation Detail for Redis (can restrict remote endpoint to VIRTUAL_NETWORK)" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 1100 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 10221-10231

  $RedisRule12 = New-AzureRmNetworkSecurityRuleConfig -Name InRestrictImplementationDetailLB -Description "Implementation Detail for Redis (can restrict remote endpoint to VIRTUAL_NETWORK)" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 1200 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix AzureLoadBalancer -DestinationPortRange 10221-10231
 
  $RedisRule13 = New-AzureRmNetworkSecurityRuleConfig -Name ClientCommunications-In-Vnet1 -Description "Client communication to Redis Clusters" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 1300 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix VirtualNetwork `
 -DestinationPortRange 13000-13999
 
  $RedisRule14 = New-AzureRmNetworkSecurityRuleConfig -Name ClientCommunications-In-LB1 -Description "Client communication to Redis Clusters" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 1400 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix AzureLoadBalancer `
 -DestinationPortRange 13000-13999

  $RedisRule15 = New-AzureRmNetworkSecurityRuleConfig -Name ClientCommunications-In-Vnet2 -Description "Client communication to Redis Clusters" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 1500 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix VirtualNetwork `
 -DestinationPortRange 15000-15999
 
  $RedisRule16 = New-AzureRmNetworkSecurityRuleConfig -Name ClientCommunications-In-LB2 -Description "Client communication to Redis Clusters" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 1600 `
 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix AzureLoadBalancer `
 -DestinationPortRange 15000-15999
 
  $RedisRule17 = New-AzureRmNetworkSecurityRuleConfig -Name ClientCommunications-In-Vnet3 -Description "Client communication to Redis Clusters" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 1700 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 15000-15999

  $RedisRule18 = New-AzureRmNetworkSecurityRuleConfig -Name ClientCommunications-In-LB3 -Description "Client communication to Redis Clusters" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 1800 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix AzureLoadBalancer -DestinationPortRange 15000-15999

  $RedisRule19 = New-AzureRmNetworkSecurityRuleConfig -Name AzureLoadBalancing2 -Description "Allow Azure Load Balancing" `
 -Access Allow -Protocol * -Direction Inbound -Priority 1900 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix AzureLoadBalancer -DestinationPortRange 16001

  $RedisRule20 = New-AzureRmNetworkSecurityRuleConfig -Name RedisCacheImplementaionIn -Description "Implementation Detail for Redis Clusters" `
 -Access Allow -Protocol Tcp -Direction Inbound -Priority 2000 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 20226

  $RedisRule21 = New-AzureRmNetworkSecurityRuleConfig -Name RedisCacheImplementaionOut -Description "Implementation Detail for Redis Clusters" `
 -Access Allow -Protocol Tcp -Direction Outbound -Priority 2100 `
 -SourceAddressPrefix * -SourcePortRange * `
 -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 20226
 #endregion

##Build NSGs
#region
$WafNsg = New-AzureRmNetworkSecurityGroup -Name "WafNsg" -ResourceGroupName $RgName -Location $Region`
                                          -SecurityRules $WAFRule1,$WAFRule2,$WAFRule3,$WAFRule4,$WAFRule5,$WAFRule6,$WAFRule7,$WAFRule8,$WAFRule9,$WAFRule10,$WAFRule11,$WAFRule12 -Force
$AseWebNsg = New-AzureRmNetworkSecurityGroup -Name "AseWebNsg" -ResourceGroupName $RgName -Location $Region`
                                             -SecurityRules $ASERule1,$ASERule2,$ASERule3,$ASERule4,$ASERule5,$ASERule6,$ASERule7,$ASERule8,$ASERule9,$ASERule10,$ASERule11,$ASERule12,$ASERule13 -Force
$AseApiNsg = New-AzureRmNetworkSecurityGroup -Name "AseApiNsg" -ResourceGroupName $RgName -Location $Region`
                                             -SecurityRules $ASERule1,$ASERule2,$ASERule3,$ASERule4,$ASERule5,$ASERule6,$ASERule7,$ASERule8,$ASERule9,$ASERule10,$ASERule11,$ASERule12,$ASERule13 -Force
$RedisNsg = New-AzureRmNetworkSecurityGroup -Name "RedisNsg" -ResourceGroupName $RgName -Location $Region`
                                            -SecurityRules $RedisRule1,$RedisRule2,$RedisRule3,$RedisRule4,$RedisRule5,$RedisRule6,$RedisRule7,$RedisRule8,$RedisRule9,$RedisRule10,$RedisRule11,$RedisRule12,$RedisRule13,$RedisRule14,$RedisRule15,$RedisRule16,$RedisRule17,$RedisRule18,$RedisRule19,$RedisRule20,$RedisRule21 -Force
#endregion

##Apply NSGs to vNet
#region
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RgName -Name $VnetName
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vnet.Subnets.name[0] `
                                      -AddressPrefix $vnet.Subnets.AddressPrefix[0]`
                                      -NetworkSecurityGroup $WafNSG
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
 
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RgName -Name $VnetName
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vnet.Subnets.name[1] `
                                      -AddressPrefix $vnet.Subnets.AddressPrefix[1]`
                                      -NetworkSecurityGroup $AseWebNSG
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RgName -Name $VnetName
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vnet.Subnets.name[2] `
                                      -AddressPrefix $vnet.Subnets.AddressPrefix[2]`
                                      -NetworkSecurityGroup $AseApiNSG
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RgName -Name $VnetName
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vnet.Subnets.name[3] `
                                      -AddressPrefix $vnet.Subnets.AddressPrefix[3]`
                                      -NetworkSecurityGroup $RedisNsg
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
#endregion

##Set SQl Firewall Rules
New-AzureRmSqlServerFirewallRule -ResourceGroupName $RgName -ServerName $SQLName `
                                 -FirewallRuleName "ILBOutboundAddress" `
                                 -StartIpAddress $hostingInfo.outboundIpAddresses[0] `
                                 -EndIpAddress $hostingInfo.outboundIpAddresses[0] 
 
