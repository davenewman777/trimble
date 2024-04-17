targetScope = 'subscription'

metadata name = 'ALZ Bicep - Virtual Network Peering to vWAN'
metadata description = 'Module used to set up Virtual Network Peering from Virtual Network back to vWAN'

@sys.description('Virtual WAN Hub resource ID.')
param parVirtualWanHubResourceId string

@sys.description('Remote Spoke virtual network resource ID.')
param parRemoteVirtualNetworkResourceId string

@sys.description('Optional Virtual Hub Connection Name Prefix.')
param parVirtualHubConnectionPrefix string = ''

@sys.description('Optional Virtual Hub Connection Name Suffix. Example: -vhc')
param parVirtualHubConnectionSuffix string = '-vhc'

@sys.description('Enable Internet Security for the Virtual Hub Connection.')
param parEnableInternetSecurity bool = false

@sys.description('Set Parameter to true to Opt-out of deployment telemetry. Default: false')
param parTelemetryOptOut bool = false

// Customer Usage Attribution Id
var varCuaid = '7b5e6db2-1e8c-4b01-8eee-e1830073a63d'

var varVwanSubscriptionId = split(parVirtualWanHubResourceId, '/')[2]

var varVwanResourceGroup = split(parVirtualWanHubResourceId, '/')[4]

var varSpokeVnetName = split(parRemoteVirtualNetworkResourceId, '/')[8]

var varModhubVirtualNetworkConnectionDeploymentName = take('deploy-vnet-peering-vwan-${varSpokeVnetName}', 64)

// The hubVirtualNetworkConnection resource is implemented as a separate module because the deployment scope could be on a different subscription and resource group
module modhubVirtualNetworkConnection 'hubVirtualNetworkConnection.bicep' = if (!empty(parVirtualWanHubResourceId) && !empty(parRemoteVirtualNetworkResourceId)) {
  scope: resourceGroup(varVwanSubscriptionId, varVwanResourceGroup)
  name: varModhubVirtualNetworkConnectionDeploymentName
  params: {
    parVirtualWanHubResourceId: parVirtualWanHubResourceId
    parRemoteVirtualNetworkResourceId: parRemoteVirtualNetworkResourceId
    parVirtualHubConnectionPrefix: parVirtualHubConnectionPrefix
    parVirtualHubConnectionSuffix: parVirtualHubConnectionSuffix
    parEnableInternetSecurity: parEnableInternetSecurity
  }
}


output outHubVirtualNetworkConnectionName string = modhubVirtualNetworkConnection.outputs.outHubVirtualNetworkConnectionName
output outHubVirtualNetworkConnectionResourceId string = modhubVirtualNetworkConnection.outputs.outHubVirtualNetworkConnectionResourceId
