targetScope = 'subscription'

param resourceGroupName string
param location string = 'westeurope'
param tags object

//creates the VNET resource group, if not exists
resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupName
  location: location
  tags: tags
} 

//OUTPUTS
output ResourceGroupId string = resourceGroup.id