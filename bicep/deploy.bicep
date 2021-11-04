param prefix string = 'gbb'
param location string = 'eastus'
param vnetAddressPrefixes string = '10.0.0.0/16'

param AzureFirewallSubnetInfo object = {
  name: 'AzureFirewallSubnet'
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}

param AksSubnetInfo object = {
  name: 'AksSubnet'
  properties: {
    addressPrefix: '10.0.4.0/22'
  }
}

resource vnet2 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: '${prefix}-${location}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefixes
      ]
    }
    subnets: [
      AzureFirewallSubnetInfo
      AksSubnetInfo
    ]
  }
}
