targetScope = 'resourceGroup'

//Global params and variables
param keyVaultName string
param location string = 'westeurope'
param tags object = {}
param currentDeploymentIdentityObjectId string
param omsResourceId string
// param omsOutputs object
// param acrOutputs object
// param vnetOutputs object
// param aksOutputs object

resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
    enableRbacAuthorization: false
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
    accessPolicies: [
      {
        objectId: currentDeploymentIdentityObjectId //to ensure access to deploy credentials for future redeployments
        tenantId: subscription().tenantId
        permissions: {
          keys: [
            'get'
            'list'
            'update'
            'create'
            'delete'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
          ]
          certificates: [
            'get'
            'list'
            'update'
            'create'
            'delete'
          ]
        }
      }
    ]
  }
}

resource acrInsights 'Microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: '${keyvault.name}_AllEvents'
  scope: keyvault
  properties: {
    workspaceId: omsResourceId
    logs: [
      {
        category: 'AuditEvent'
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


// //Store OMS output values as KV Secrets
// resource omsWorkspaceId 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/oms.workspaceId'  
//   properties: {
//     value: omsOutputs.OmsWorkspaceId
//     contentType: '${keyvault.name}/oms.workspaceId'
//   }
// }
// resource omsResourceId 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/oms.resourceId'  
//   properties: {
//     value: omsOutputs.OmsId
//     contentType: '${keyvault.name}/oms.resourceId'
//   }
// }
// resource omsWorkspaceName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/oms.workspaceName'  
//   properties: {
//     value: omsOutputs.OmsWorkspaceName
//     contentType: '${keyvault.name}/oms.workspaceName'
//   }
// }
// resource omsContainerSolutionId 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/oms.containerSolutionId'  
//   properties: {
//     value: omsOutputs.OmsContainerSolutionId
//     contentType: '${keyvault.name}/oms.containerSolutionId'
//   }
// }
// resource omsResourceGroupName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/oms.resourceGroupName'  
//   properties: {
//     value: omsOutputs.OmsResourceGroupName
//     contentType: '${keyvault.name}/oms.resourceGroupName'
//   }
// }

// //Store ACR output values as KV Secrets
// resource acrResourceId 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/acr.resourceId'  
//   properties: {
//     value: acrOutputs.AcrResourceId
//     contentType: '${keyvault.name}/acr.resourceId'
//   }
// }
// resource acrName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/acr.name'  
//   properties: {
//     value: acrOutputs.AcrName
//     contentType: '${keyvault.name}/acr.name'
//   }
// }
// resource acrFQDN 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/acr.fqdn'  
//   properties: {
//     value: acrOutputs.AcrFQDN
//     contentType: '${keyvault.name}/acr.fqdn'
//   }
// }
// resource acrResourceGroupName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/acr.resourceGroupName'  
//   properties: {
//     value: acrOutputs.AcrResourceGroupName
//     contentType: '${keyvault.name}/acr.resourceGroupName'
//   }
// }


// //Store VNET output values as KV Secrets
// resource vnetResourceId 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/vnet.resourceId'  
//   properties: {
//     value: vnetOutputs.VnetId
//     contentType: '${keyvault.name}/vnet.resourceId'
//   }
// }
// resource subnetResourceId'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/subnet.resourceId'  
//   properties: {
//     value: vnetOutputs.SubnetId
//     contentType: '${keyvault.name}/subnet.resourceId'
//   }
// }
// resource vnetResourceGroupName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/vnet.resourceGroupName'  
//   properties: {
//     value: vnetOutputs.VnetResourceGroupName
//     contentType: '${keyvault.name}/vnet.resourceGroupName'
//   }
// }

// //Store AKS output values as KV Secrets
// resource aksResourceId 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/aks.resourceId'  
//   properties: {
//     value: aksOutputs.AksResourceId
//     contentType: '${keyvault.name}/aks.resourceId'
//   }
// }
// resource aksResourceGroupName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/aks.resourceGroupName'  
//   properties: {
//     value: aksOutputs.AksResourceGroupName
//     contentType: '${keyvault.name}/aks.resourceGroupName'
//   }
// }
// resource aksClusterName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/aks.name'  
//   properties: {
//     value: aksOutputs.AksClusterName
//     contentType: '${keyvault.name}/aks.name'
//   }
// }
// resource aksControlPlaneFQDN 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/aks.controlPlaneFQDN'  
//   properties: {
//     value: aksOutputs.AksControlPlaneFQDN
//     contentType: '${keyvault.name}/aks.controlPlaneFQDN'
//   }
// }
// resource aksKubeletIdentity 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/aks.kubeletIdentity'  
//   properties: {
//     value: aksOutputs.AksKubeletIdentity
//     contentType: '${keyvault.name}/aks.kubeletIdentity'
//   }
// }
// resource aksOmsAgentIdentity 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/aks.omsAgentIdentity'  
//   properties: {
//     value: aksOutputs.AksOmsAgentIdentity
//     contentType: '${keyvault.name}/aks.omsAgentIdentity'
//   }
// }
// resource aksManagedIdentityId 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
//   name: '${keyvault.name}/aks.managedIdentityId'  
//   properties: {
//     value: aksOutputs.AksManagedIdentityId
//     contentType: '${keyvault.name}/aks.managedIdentityId'
//   }
// }

//OUTPUTS
output KeyVaultResourceId string = keyvault.id
output KeyVaultNamestring string = keyvault.name
output KeyVaultUri string = keyvault.properties.vaultUri