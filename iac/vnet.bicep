targetScope = 'resourceGroup'

//Global params and variables
param vnetName string
param subnetName string
param vnetAddressPrefix string
param subnetAddressPrefix string 
param location string = 'westeurope'
param tags object = {}
param omsResourceId string

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

//populate logs and metrics from vnet service.
resource omsInsights 'Microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: '${vnet.name}_AllEvents'
  scope: vnet
  properties: {
    workspaceId: omsResourceId
    logs: [
      {
        category: 'VMProtectionAlerts'
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
output VnetId string = vnet.id
output SubnetId string = '${vnet.id}/subnets/${subnetName}'
output VnetResourceGroupName string = resourceGroup().name