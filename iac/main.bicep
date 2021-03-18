targetScope = 'managementGroup'

//Global params and variables
param subscriptionId string
param projectName string {
  default: 'ModApp'
  minLength: 1
  maxLength: 11
}
param environmentPrefix string = 'Poc'
param environmentName string = 'Prueba de Concepto'
param projectDescription string = 'Webinar Modernización de Aplicaciones'
param ResourcesLocation string = 'westeurope'

param currentDeploymentIdentityObjectId string //objectId of identity used in the current deployment context
param resourceTags object = {
  'Entorno': environmentName
  'Proyecto': projectDescription
}

param sharedResourceGroupName string = '${environmentPrefix}${projectName}-Shared'
var keyvaultName = '${environmentPrefix}${projectName}-kv'

//VNET params
var vnetName = '${environmentPrefix}${projectName}-Vnet'
var subnetName = '${projectName}-AksSubnet'
param vnetAddressPrefix string 
param subnetAddressPrefix string 

//OMS Params
var omsName = '${environmentPrefix}${projectName}-Oms'

//ACR Params
var acrName = '${environmentPrefix}${projectName}Acr' //may contain alpha numeric characters only and must be between 5 and 50 characters

//AKS params 
param aksResourceGroupName string = '${environmentPrefix}${projectName}-Aks'
param AADGroupClusterAdminsObjectId string //objectId of the Azure AD group used for AKS administrators
var aksName = '${environmentPrefix}${projectName}-Aks'

//Creates OMS and Container solution
module omsResourceGroup './resourceGroup.bicep' = {
  name: 'omsResourceGroup'
  scope: subscription(subscriptionId)
  params: {    
    location: ResourcesLocation
    tags: resourceTags
    resourceGroupName: sharedResourceGroupName
  }
}
module omsModule './oms.bicep' = {
  name: 'oms'
  dependsOn: [
    omsResourceGroup
  ]
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)
  params: {   
    location: ResourcesLocation
    tags: resourceTags
    omsName: omsName
  }
}

//ACR creation
module acrResourceGroup './resourceGroup.bicep' = {
  name: 'acrResourceGroup'
  scope: subscription(subscriptionId)
  params: {    
    location: ResourcesLocation
    tags: resourceTags
    resourceGroupName: sharedResourceGroupName
  }
}
module acrModule './acr.bicep' = {
  name: 'acr'
  dependsOn: [
    acrResourceGroup
    omsModule
  ]
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)
  params: {    
    location: ResourcesLocation
    tags: resourceTags
    acrName: acrName
    omsResourceId: omsModule.outputs.OmsId
  }
}

//VNET creation
module vnetResourceGroup './resourceGroup.bicep' = {
  name: 'vnetResourceGroup'
  scope: subscription(subscriptionId)
  params: {
    location: ResourcesLocation
    tags: resourceTags
    resourceGroupName: sharedResourceGroupName
  }
}
module vnetModule './vnet.bicep' = {
  name: 'vnet'
  dependsOn: [
    vnetResourceGroup
    omsModule
  ]
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)
  params: {
    location: ResourcesLocation
    tags: resourceTags
    vnetName: vnetName
    subnetName: subnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnetAddressPrefix: subnetAddressPrefix
    omsResourceId: omsModule.outputs.OmsId
  }
}

//AKS creation
module aksResourceGroup './resourceGroup.bicep' = {
  name: 'aksResourceGroup'
  scope: subscription(subscriptionId)
  params: {    
    location: ResourcesLocation
    tags: resourceTags
    resourceGroupName: aksResourceGroupName
  }
}
module aksModule './aks.bicep' = {
  name: 'aks'
  dependsOn: [
    aksResourceGroup
    omsModule
    acrModule
    vnetModule
  ]
  scope: resourceGroup(subscriptionId, aksResourceGroupName)
  params: {
    location: ResourcesLocation
    tags: resourceTags
    AADGroupClusterAdminsObjectId: AADGroupClusterAdminsObjectId
    aksName: aksName
    vnetSubnetID: vnetModule.outputs.SubnetId
    omsResourceId:  omsModule.outputs.OmsId    
  }
}

//set AKS permissions
module aksSubnetPermissions './permissions.vnet.bicep' = {
  name: 'aksSubnetPermissions'
  dependsOn: [
    aksModule
    vnetModule
  ]
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)
  params: {
    aksSubnetResourceId:  vnetModule.outputs.SubnetId
    aksResourceId: aksModule.outputs.AksResourceId
    aksManagedIdentityId: aksModule.outputs.AksManagedIdentityId
  }
}
module acrPermissionsModule './permissions.acr.bicep' = {
  name: 'acrPermissions'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)
  dependsOn: [
    aksModule 
    acrModule
  ]
  params: {
    acrResourceId: acrModule.outputs.AcrResourceId
    aksResourceId: aksModule.outputs.AksResourceId
  }
}

//Create KeyVault to store output values
module kvModule './keyvault.bicep' = {
  name: 'kv'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    omsModule 
    acrModule
    vnetModule
    aksModule
  ] 
  params: {
    location: ResourcesLocation
    tags: resourceTags
    keyVaultName: keyvaultName
    currentDeploymentIdentityObjectId: currentDeploymentIdentityObjectId
    omsResourceId: omsModule.outputs.OmsId
    // omsOutputs: omsModule.outputs
    // acrOutputs: acrModule.outputs
    // vnetOutputs: vnetModule.outputs
    // aksOutputs: aksModule.outputs
  }
}


//Store OMS output values as KV Secrets
module secretOmsWorkspaceId './keyvaultSecret.bicep' = {
  name: 'secretOmsWorkspaceId'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'OmsWorkspaceId'
    secretValue: omsModule.outputs.OmsWorkspaceId
  }
}
module secretOmsResourceId './keyvaultSecret.bicep' = {
  name: 'secretOmsResourceId'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'OmsResourceId'
    secretValue: omsModule.outputs.OmsId
  }
}
module secretOmsWorkspaceName './keyvaultSecret.bicep' = {
  name: 'secretOmsWorkspaceName'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'OmsWorkspaceName'
    secretValue: omsModule.outputs.OmsWorkspaceName
  }
}
module secretOmsContainerSolutionId './keyvaultSecret.bicep' = {
  name: 'secretOmsContainerSolutionId'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'OmsContainerSolutionId'
    secretValue: omsModule.outputs.OmsContainerSolutionId
  }
}
module secretOmsResourceGroupName './keyvaultSecret.bicep' = {
  name: 'secretOmsResourceGroupName'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'OmsResourceGroupName'
    secretValue: omsModule.outputs.OmsResourceGroupName
  }
} 


//Store ACR output values as KV Secrets
module secretAcrResourceId './keyvaultSecret.bicep' = {
  name: 'secretAcrResourceId'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AcrResourceId'
    secretValue: acrModule.outputs.AcrResourceId
  }
} 
module secretAcrName './keyvaultSecret.bicep' = {
  name: 'secretAcrName'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AcrName'
    secretValue: acrModule.outputs.AcrName
  }
} 
module secretAcrFQDN './keyvaultSecret.bicep' = {
  name: 'secretAcrFQDN'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AcrFQDN'
    secretValue: acrModule.outputs.AcrFQDN
  }
}
module secretAcrResourceGroupName './keyvaultSecret.bicep' = {
  name: 'secretAcrResourceGroupName'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AcrResourceGroupName'
    secretValue: acrModule.outputs.AcrResourceGroupName
  }
}

//Store VNET output values as KV Secrets
module secretVnetResourceId './keyvaultSecret.bicep' = {
  name: 'secretVnetResourceId'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'VnetResourceId'
    secretValue: vnetModule.outputs.VnetId
  }
}
module secretSubnetResourceId './keyvaultSecret.bicep' = {
  name: 'secretSubnetResourceId'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'SubnetResourceId'
    secretValue: vnetModule.outputs.SubnetId
  }
}
module secretVnetResourceGroupName './keyvaultSecret.bicep' = {
  name: 'secretVnetResourceGroupName'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'VnetResourceGroupName'
    secretValue: vnetModule.outputs.VnetResourceGroupName
  }
} 

//Store AKS output values as KV Secrets
module secretAksResourceId './keyvaultSecret.bicep' = {
  name: 'secretAksResourceId'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AksResourceId'
    secretValue: aksModule.outputs.AksResourceId
  }
} 
module secretAksResourceGroupName './keyvaultSecret.bicep' = {
  name: 'secretAksResourceGroupName'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AksResourceGroupName'
    secretValue: aksModule.outputs.AksResourceGroupName
  }
}
module secretAksClusterName './keyvaultSecret.bicep' = {
  name: 'secretAksClusterName'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AksClusterName'
    secretValue: aksModule.outputs.AksClusterName
  }
}
module secretAksControlPlaneFQDN './keyvaultSecret.bicep' = {
  name: 'secretAksControlPlaneFQDN'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AksControlPlaneFQDN'
    secretValue: aksModule.outputs.AksControlPlaneFQDN
  }
}
module secretAksKubeletIdentity './keyvaultSecret.bicep' = {
  name: 'secretAksKubeletIdentity'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AksKubeletIdentity'
    secretValue: aksModule.outputs.AksKubeletIdentity
  }
}
module secretAksOmsAgentIdentity './keyvaultSecret.bicep' = {
  name: 'secretAksOmsAgentIdentity'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AksOmsAgentIdentity'
    secretValue: aksModule.outputs.AksOmsAgentIdentity
  }
}
module secretAksManagedIdentityId './keyvaultSecret.bicep' = {
  name: 'secretAksManagedIdentityId'
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)  
  dependsOn: [
    kvModule
  ] 
  params: {
    keyVaultName: keyvaultName
    secretName: 'AksManagedIdentityId'
    secretValue: aksModule.outputs.AksManagedIdentityId
  }
}

//OUTPUTS
output OmsId string = omsModule.outputs.OmsId
output OmsWorkspaceName string = omsModule.outputs.OmsWorkspaceName
output OmsWorkspaceId string =  omsModule.outputs.OmsWorkspaceId
output OmsContainerSolutionId string = omsModule.outputs.OmsContainerSolutionId

output AcrResourceId string = acrModule.outputs.AcrResourceId
output AcrName string = acrModule.outputs.AcrName
output AcrFQDN string = acrModule.outputs.AcrFQDN

output VnetId string = vnetModule.outputs.VnetId
output SubnetId string = vnetModule.outputs.SubnetId

output AksResourceId string = aksModule.outputs.AksResourceId
output AksControlPlaneFQDN string = aksModule.outputs.AksControlPlaneFQDN
output AksResourceGroupName string = aksModule.outputs.AksResourceGroupName
output AksKubeletIdentity string = aksModule.outputs.AksKubeletIdentity
output AksOmsAgentIdentity string = aksModule.outputs.AksOmsAgentIdentity
output AksManagedIdentityId string = aksModule.outputs.AksManagedIdentityId
output AksClusterName string = aksModule.outputs.AksClusterName