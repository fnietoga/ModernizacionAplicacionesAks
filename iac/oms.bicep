targetScope = 'resourceGroup'

//Global params and variables
param omsName string
param location string = 'westeurope'
param tags object = {}


//deploy OMS
resource oms 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: omsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    // workspaceCapping: {
    //   dailyQuotaGb: 5
    // }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
} 

//populate logs and metrics from oms service.
resource omsInsights 'Microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: '${oms.name}_AllEvents'
  scope: oms
  properties: {
    workspaceId: oms.id
    logs: [
      {
        category: 'Audit'
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

//deploy the Container Solution in Log Analitics 
resource omsContainerSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ContainerInsights(${omsName})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: oms.id
  }
  plan: {
    name: 'ContainerInsights(${omsName})'
    publisher: 'Microsoft'
    product: 'OMSGallery/ContainerInsights'
    promotionCode: ''
  }
} 

//OUTPUTS
output OmsId string = oms.id
output OmsWorkspaceName string = oms.name
output OmsWorkspaceId string = oms.properties.customerId
output OmsContainerSolutionId string = omsContainerSolution.id
output OmsResourceGroupName string = resourceGroup().name