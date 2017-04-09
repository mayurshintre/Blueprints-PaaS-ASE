#Update all variables for the resource group, location, UDRName, ExistingVnetName, and RouteName

Login-AzureRmAccount
$ResourceGroup = "RG Name Here"
$location = "LOcation Here"
$UDRName = "ASEInternetOutbound"
$ExistingVnetName = "VNet name here"
$routeName = "RouteToInternet"

$route = New-AzureRmRouteConfig -Name $routeName -AddressPrefix 0.0.0.0/0 -NextHopType Internet
$routeTable = New-AzureRmRouteTable -ResourceGroupName $ResourceGroup -Location $location -Name $UDRName -Route $route
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroup -Name $ExistingVnetName
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $Vnet.Subnets[0].Name -AddressPrefix $vnet.Subnets[0].AddressPrefix -RouteTable $routeTable
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $Vnet.Subnets[1].Name -AddressPrefix $vnet.Subnets[1].AddressPrefix -RouteTable $routeTable
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $Vnet.Subnets[2].Name -AddressPrefix $vnet.Subnets[2].AddressPrefix -RouteTable $routeTable
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $Vnet.Subnets[3].Name -AddressPrefix $vnet.Subnets[3].AddressPrefix -RouteTable $routeTable
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet