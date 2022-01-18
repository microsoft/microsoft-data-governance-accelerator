@description('Name of the resource')
param purviewAccountName string
param location string

resource purviewAccountName_resource 'Microsoft.Purview/accounts@2020-12-01-preview' = {
  name: purviewAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  sku: {
    name: 'Standard'
    capacity: 4
  }
  tags: {}
  dependsOn: []
}
