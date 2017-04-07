#Install PowerShell via aka.ms/webpi-azps
#dynamically get each ase environement's ips. 1 for webapp (done) one for API 
#dynamically set subscription - outgrid
#waf backend address pool needs internal ips of both ilbs
#waf outbound nsg to api and webapp

Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName "Microsoft Azure Internal Consumption"
Connect-MsolService
$DirectoryInfo =  Get-MsolCompanyInformation
$aadtenant = $DirectoryInfo.DirSyncServiceAccount.Split("{@}")[1]
$resourceID = (Get-AzureRmResource | where -Property resourcename -EQ "asev1").resourceID

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
$hostingInfo.serviceIpAddress

  $WAFRule1 = New-AzureRmNetworkSecurityRuleConfig -Name DenyAllInbound -Description "Deny All Inbound" `
 -Access Allow -Protocol * -Direction Inbound -Priority 100 `
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
 -Access Allow -Protocol * -Direction Outbound -Priority 100 `
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

$WAFNSG = New-AzureRmNetworkSecurityGroup -Name "WAFNSG" -ResourceGroupName "ASEV1" -Location "WestUS" -SecurityRules $WAFRule1,$WAFRule2,$WAFRule3,$WAFRule4,$WAFRule5,$WAFRule6,$WAFRule7,$WAFRule8,$WAFRule9,$WAFRule10,$WAFRule11,$WAFRule12 -Force
$ASEWebNSG = New-AzureRmNetworkSecurityGroup -Name "WebASENSG" -ResourceGroupName "ASEV1" -Location "WestUS" -SecurityRules $ASERule1,$ASERule2,$ASERule3,$ASERule4,$ASERule5,$ASERule6,$ASERule7,$ASERule8,$ASERule9,$ASERule10,$ASERule11,$ASERule12,$ASERule13 -Force
$ASEApiNSG = New-AzureRmNetworkSecurityGroup -Name "ApiASENSG" -ResourceGroupName "ASEV1" -Location "WestUS" -SecurityRules $ASERule1,$ASERule2,$ASERule3,$ASERule4,$ASERule5,$ASERule6,$ASERule7,$ASERule8,$ASERule9,$ASERule10,$ASERule11,$ASERule12,$ASERule13 -Force
$RedisNSG = New-AzureRmNetworkSecurityGroup -Name "RedisENSG" -ResourceGroupName "ASEV1" -Location "WestUS" -SecurityRules $RedisRule1,$RedisRule2,$RedisRule3,$RedisRule4,$RedisRule5,$RedisRule6,$RedisRule7,$RedisRule8,$RedisRule9,$RedisRule10,$RedisRule11,$RedisRule12,$RedisRule13,$RedisRule14,$RedisRule15,$RedisRule16,$RedisRule17,$RedisRule18,$RedisRule19,$RedisRule20,$RedisRule21 -Force

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName ASEV1 -Name asev1-vnet
 Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vnet.Subnets.name[0] `
 -AddressPrefix $vnet.Subnets.AddressPrefix[0] -NetworkSecurityGroup $ASEWebNSG

 Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
 
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName ASEV1 -Name asev1-vnet
 Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vnet.Subnets.name[1] `
 -AddressPrefix $vnet.Subnets.AddressPrefix[1] -NetworkSecurityGroup $ASEApiNSG

 Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName ASEV1 -Name asev1-vnet
 Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vnet.Subnets.name[2] `
 -AddressPrefix $vnet.Subnets.AddressPrefix[2] -NetworkSecurityGroup $WAFNSG

 Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

 $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName ASEV1 -Name asev1-vnet
 Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vnet.Subnets.name[3] `
 -AddressPrefix $vnet.Subnets.AddressPrefix[3] -NetworkSecurityGroup $RedisNSG

Set-AzureRmVirtualNetwork -VirtualNetwork $vnet