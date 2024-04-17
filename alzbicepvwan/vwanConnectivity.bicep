metadata name = 'ALZ Bicep - Azure vWAN Connectivity Module'
metadata description = 'Module used to set up vWAN Connectivity'

type virtualWanOptionsType = ({
  @sys.description('Switch to enable/disable VPN Gateway deployment on the respective Virtual WAN Hub.')
  parVpnGatewayEnabled: bool

  @sys.description('Switch to enable/disable ExpressRoute Gateway deployment on the respective Virtual WAN Hub.')
  parExpressRouteGatewayEnabled: bool

  @sys.description('Switch to enable/disable Azure Firewall deployment on the respective Virtual WAN Hub.')
  parAzFirewallEnabled: bool

  @sys.description('The IP address range in CIDR notation for the vWAN virtual Hub to use.')
  parVirtualHubAddressPrefix: string

  @sys.description('The Virtual WAN Hub location.')
  parHubLocation: string

  @sys.description('Name for Virtual WAN Hub.')
  parVirtualWanHubName: string

  @sys.description('The Virtual WAN Hub routing preference. The allowed values are `ASN`, `VpnGateway`, `ExpressRoute`.')
  parHubRoutingPreference: ('ExpressRoute' | 'VpnGateway' | 'ASN')

  @sys.description('The Virtual WAN Hub capacity. The value should be between 2 to 50.')
  @minValue(2)
  @maxValue(50)
  parVirtualRouterAutoScaleConfiguration: int

  @sys.description('The Virtual WAN Hub routing intent destinations, leave empty if not wanting to enable routing intent. The allowed values are `Internet`, `PrivateTraffic`.')
  parVirtualHubRoutingIntentDestinations: ('Internet' | 'PrivateTraffic')[]

  @sys.description('This parameter is used to specify a custom name for the VPN Gateway.')
  parVpnGatewayCustomName: string?

  @sys.description('This parameter is used to specify a custom name for the ExpressRoute Gateway.')
  parExpressRouteGatewayCustomName: string?

  @sys.description('This parameter is used to specify a custom name for the Azure Firewall.')
  parAzFirewallCustomName: string?

  @sys.description('This parameter is used to specify a custom name for the Virtual WAN Hub.')
  parVirtualWanHubCustomName: string?
})[]

@sys.description('Region in which the resource group was created.')
param parLocation string = resourceGroup().location

@sys.description('Prefix value which will be prepended to all resource names.')
param parCompanyPrefix string = 'cis'

@sys.description('Switch to enable/disable Virtual Hub deployment.')
param parVirtualHubEnabled bool = true

@sys.description('Prefix Used for Virtual WAN.')
param parVirtualWanName string = '${parCompanyPrefix}-am-cus-vwan-001'



@sys.description('''Array Used for multiple Virtual WAN Hubs deployment. Each object in the array represents an individual Virtual WAN Hub configuration. Add/remove additional objects in the array to meet the number of Virtual WAN Hubs required.

- `parVpnGatewayEnabled` - Switch to enable/disable VPN Gateway deployment on the respective Virtual WAN Hub.
- `parExpressRouteGatewayEnabled` - Switch to enable/disable ExpressRoute Gateway deployment on the respective Virtual WAN Hub.
- `parAzFirewallEnabled` - Switch to enable/disable Azure Firewall deployment on the respective Virtual WAN Hub.
- `parVirtualHubAddressPrefix` - The IP address range in CIDR notation for the vWAN virtual Hub to use.
- `parHubLocation` - The Virtual WAN Hub location.
- 'parVirtualWanHubName'  - Name of the VWANHub
- `parHubRoutingPreference` - The Virtual WAN Hub routing preference. The allowed values are `ASN`, `VpnGateway`, `ExpressRoute`.
- `parVirtualRouterAutoScaleConfiguration` - The Virtual WAN Hub capacity. The value should be between 2 to 50.
- `parVirtualHubRoutingIntentDestinations` - The Virtual WAN Hub routing intent destinations, leave empty if not wanting to enable routing intent. The allowed values are `Internet`, `PrivateTraffic`.

''')
param parVirtualWanHubs virtualWanOptionsType = [ {
    parVpnGatewayEnabled: false
    parExpressRouteGatewayEnabled: false
    parAzFirewallEnabled: false
    parVirtualHubAddressPrefix: '10.234.0.0/16'
    parHubLocation: 'centralus'
    parVirtualWanHubName: 'cis-am-cus-hub-001'
    parHubRoutingPreference: 'VpnGateway'
    parVirtualRouterAutoScaleConfiguration: 2
    parVirtualHubRoutingIntentDestinations: ['PrivateTraffic']
  }
  {
    parVpnGatewayEnabled: false
    parExpressRouteGatewayEnabled: false
    parAzFirewallEnabled: false
    parVirtualHubAddressPrefix: '10.236.0.0/16'
    parHubLocation: 'germanywestcentral'
    parVirtualWanHubName: 'cis-eu-gwc-hub-001'
    parHubRoutingPreference: 'VpnGateway'
    parVirtualRouterAutoScaleConfiguration: 2
    parVirtualHubRoutingIntentDestinations: ['PrivateTraffic']
  }
  {
    parVpnGatewayEnabled: false
    parExpressRouteGatewayEnabled: false
    parAzFirewallEnabled: false
    parVirtualHubAddressPrefix: '10.239.0.0/16'
    parHubLocation: 'southeastasia'
    parVirtualWanHubName: 'cis-ap-sea-hub-001'
    parHubRoutingPreference: 'VpnGateway'
    parVirtualRouterAutoScaleConfiguration: 2
    parVirtualHubRoutingIntentDestinations: ['PrivateTraffic']
  }
]

@sys.description('List of required tags')
param parTagBusiness_Owner string = ''
param parTagTechnical_Owner string = ''
param parTagBusiness_Unit string = ''
param parTagTicket string = ''
param parTagOS_patching string = ''
param parTagSoftware_patching string = ''
param parTagBackup string = ''
param parTagProduct string =''
param parTagEnvironment string =''


@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {
  business_owner: parTagBusiness_Owner
  technical_owner: parTagTechnical_Owner
  business_unit: parTagBusiness_Unit
  ticket: parTagTicket
  'os-patching': parTagOS_patching
  'software-patching': parTagSoftware_patching
  backup: parTagBackup
  product: parTagProduct
  environment: parTagEnvironment
}

// Virtual WAN resource
resource resVwan 'Microsoft.Network/virtualWans@2023-04-01' = {
  name: parVirtualWanName
  location: parLocation
  tags: parTags
  properties: {
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
    disableVpnEncryption: false
    type: 'Standard'
  }
}

resource resVhub 'Microsoft.Network/virtualHubs@2023-04-01' = [for hub in parVirtualWanHubs: if (parVirtualHubEnabled && !empty(hub.parVirtualHubAddressPrefix)) {
  name: hub.parVirtualWanHubName
  location: hub.parHubLocation
  tags: parTags
  properties: {
    addressPrefix: hub.parVirtualHubAddressPrefix
    sku: 'Standard'
    virtualWan: {
      id: resVwan.id
    }
    virtualRouterAutoScaleConfiguration: {
      minCapacity: hub.parVirtualRouterAutoScaleConfiguration
    }
    hubRoutingPreference: hub.parHubRoutingPreference
  }
}]

resource resVhubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2023-04-01' = [for (hub, i) in parVirtualWanHubs: if (parVirtualHubEnabled && hub.parAzFirewallEnabled && empty(hub.parVirtualHubRoutingIntentDestinations)) {
  parent: resVhub[i]
  name: 'defaultRouteTable'
  properties: {
    labels: [
      'default'
    ]
    routes: [
     
    ]
  }
}]

resource resVhubRoutingIntent 'Microsoft.Network/virtualHubs/routingIntent@2023-04-01' = [for (hub, i) in parVirtualWanHubs: if (parVirtualHubEnabled && hub.parAzFirewallEnabled && !empty(hub.parVirtualHubRoutingIntentDestinations)) {
  parent: resVhub[i]
  name: !empty(hub.?parVirtualWanHubCustomName) ? '${hub.parVirtualWanHubCustomName}-Routing-Intent' : '${hub.parVirtualWanHubName}-Routing-Intent'
  properties: {
    routingPolicies: [for destination in hub.parVirtualHubRoutingIntentDestinations: {
      name: destination == 'Internet' ? 'PublicTraffic' : destination == 'PrivateTraffic' ? 'PrivateTraffic' : 'N/A'
      destinations: [
        destination
      ]
      nextHop: '0.0.0.0'
    }]
  }
}]


// Output Virtual WAN name and ID
output outVirtualWanName string = resVwan.name
output outVirtualWanId string = resVwan.id

// Output Virtual WAN Hub name and ID
output outVirtualHubName array = [for (hub, i) in parVirtualWanHubs: {
  virtualhubname: resVhub[i].name
  virtualhubid: resVhub[i].id
}]

output outVirtualHubId array = [for (hub, i) in parVirtualWanHubs: {
  virtualhubid: resVhub[i].id
}]

