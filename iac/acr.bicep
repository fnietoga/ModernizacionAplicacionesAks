targetScope = 'resourceGroup'

//Global params and variables
param acrName string
param location string = 'westeurope'
param tags object = {}
param omsResourceId string

resource acr 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    // networkRuleSet: {
    //   defaultAction: 'Allow'
    //   virtualNetworkRules: []
    //   ipRules: []
    // }
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
    }
    encryption: {
      status: 'disabled'
      // keyVaultProperties: {}
    }
    publicNetworkAccess: 'Enabled'
    dataEndpointEnabled: false
  }
}
resource acrInsights 'Microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: '${acr.name}_AllEvents'
  scope: acr
  properties: {
    workspaceId: omsResourceId
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

//OUTPUTS
output AcrResourceId string = acr.id
output AcrName string = acr.name
output AcrFQDN string = '${acr.name}.azurecr.io'
output AcrResourceGroupName string = resourceGroup().name