targetScope = 'resourceGroup'

param aksSubnetResourceId string //resourceId of existing subnet to be used for AKS
param aksResourceId string //ResourceId of the AKS to find the kubeletidentity to be assigned
param aksManagedIdentityId string //ObjectId of the system assigned managed identity of AKS cluster

//Set aks permissions on subnet
var vnetName = split(aksSubnetResourceId, '/')[8]
var subnetName = split(aksSubnetResourceId, '/')[10]
resource askKubeletPermissionsSubnet 'Microsoft.Network/virtualNetworks/subnets/providers/roleAssignments@2020-04-01-preview' = {
  name: '${vnetName}/${subnetName}/Microsoft.Authorization/${guid(resourceGroup().id, aksSubnetResourceId, 'kubelet')}'
  properties: {
    principalId: reference(aksResourceId, '2020-03-01').identityProfile.kubeletidentity.objectId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7' //Network Contributor 
    scope: aksSubnetResourceId
  }
}

resource askManagedPermissionsSubnet 'Microsoft.Network/virtualNetworks/subnets/providers/roleAssignments@2020-04-01-preview' = {
  name: '${vnetName}/${subnetName}/Microsoft.Authorization/${guid(resourceGroup().id, aksSubnetResourceId, 'managed')}'
  properties: {
    principalId: aksManagedIdentityId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7' //Network Contributor 
    scope: aksSubnetResourceId
  }
}

//OUTPUTS
output AskKubeletPermissionsOnSubnetId string = askKubeletPermissionsSubnet.id
output AskManagedPermissionsOnSubnetIs string = askManagedPermissionsSubnet.id