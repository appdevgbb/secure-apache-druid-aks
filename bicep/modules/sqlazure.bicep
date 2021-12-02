param prefix string 
param location string = resourceGroup().location
param adminUsername string
param adminPassword string
param sqlDBName string = 'gbb-corp'

param baseTime string = utcNow('u')
var sqlBasename = guid(prefix,adminUsername,adminPassword,baseTime)
resource azuresql 'Microsoft.Sql/servers@2020-11-01-preview' = {
  name: '${sqlBasename}-sqlserver'
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    minimalTlsVersion: '1.2'
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${azuresql.name}/${sqlDBName}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

output name string = azuresql.name
