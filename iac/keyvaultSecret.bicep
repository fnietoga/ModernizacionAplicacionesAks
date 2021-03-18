targetScope = 'resourceGroup'

//Global params and variables
param keyVaultName string
param secretName string
param secretValue string
param location string = 'westeurope'
param tags object = {}

resource omsWorkspaceId 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
    name: '${keyVaultName}/${secretName}'
    properties: {
      value: secretValue
      contentType: '${keyVaultName}/${secretName}'
    }
  }
  