/* Naming convention requirements */
param prefix string = 'gbb'
param location string = 'eastus'
param name string = 'test'

/* Linux jumpbox Config */
var jumpName = '${name}-jump'
param adminUsername string
param adminPublicKey string

/* SQL Config */
param sqlAdminUsername string
param sqlAdminPassword string

/* Network Settings */
param vnetAddressPrefixes string = '10.0.0.0/16'

param aksSubnetInfo object = {
  name: 'AksSubnet'
  properties: {
    addressPrefix: '10.0.4.0/22'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}
param jumpboxSubnetInfo object = {
  name: 'JumpboxSubnet'
  properties: {
    addressPrefix: '10.0.255.240/28'
  }
}

param AzureFirewallSubnetInfo object = {
  name: 'AzureFirewallSubnet'
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
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
      aksSubnetInfo
      jumpboxSubnetInfo
    ]
  }
}

module sqlServer 'modules/sqlazure.bicep' = {
  name: 'sqlserver'
  params: {
    prefix: prefix
    adminUsername: sqlAdminUsername
    adminPassword: sqlAdminPassword
  }
}

module aks 'modules/aks.bicep' = {
  name: 'aks-deployment'
  params: {
    prefix: prefix
    subnetId: '${vnet.id}/subnets/${aksSubnetInfo.name}'
  }

}

module jump 'modules/jump.bicep' = {
  name: '${jumpName}-deployment'
  params: {
    name: jumpName
    subnetId: '${vnet.id}/subnets/${jumpboxSubnetInfo.name}'
    adminUsername: adminUsername
    adminPublicKey: adminPublicKey
  }
}

/* Outputs */
output aksName string = aks.outputs.name
output sqlServerName string = sqlServer.outputs.name
output jumpboxIP string = jump.outputs.jumpPublicIP
