targetScope = 'resourceGroup'

param acrResourceId string //resourceId of existing subnet to be used for AKS
param aksResourceId string //ResourceId of the AKS to find the kubeletidentity to be assigned
 
//Set aks permissions on acr
var acrName = split(acrResourceId, '/')[8]
resource aksPermissionsAcr 'Microsoft.ContainerRegistry/registries/providers/roleAssignments@2020-04-01-preview' = {
  name: '${acrName}/Microsoft.Authorization/${guid(resourceGroup().id, acrResourceId, 'kubelet')}'
  properties: {
    principalId: reference(aksResourceId, '2020-03-01').identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d' //AcrPull
    scope: acrResourceId
  }
}