targetScope = 'resourceGroup'

//Global params and variables
param aksName string
param location string = 'westeurope'
param tags object = {}
param AADGroupClusterAdminsObjectId string 
param vnetSubnetID string 
param omsResourceId string

resource aks 'Microsoft.ContainerService/managedClusters@2020-09-01' = {
  name: aksName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.18.10'
    enableRBAC: true
    dnsPrefix: '${aksName}-dns'
    nodeResourceGroup: '${resourceGroup().name}_Resources'
    agentPoolProfiles: [
      {
        name: 'masterlinux'
        osDiskSizeGB: 64
        //availabilityZones: []
        count: 2
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System' //at least 1 system pool
        osDiskType: 'Managed'
        enableAutoScaling: false
        maxPods: 110
        // minCount: 2
        // maxCount: 4
        enableNodePublicIP: false
        scaleSetEvictionPolicy: 'Deallocate'
        vnetSubnetID: vnetSubnetID  //'${vnet.id}/subnets/${subnetName}'
      }
    ]
    aadProfile: {
      managed: true
      //enableAzureRBAC: true  //en Preview
      adminGroupObjectIDs: [
        AADGroupClusterAdminsObjectId
      ]
      tenantID: subscription().tenantId
      //clientAppID: ''
      //serverAppID: ''
    }
    autoScalerProfile: {}
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'standard'
      // dnsServiceIP: '10.0.0.10'
      // serviceCidr: '10.0.0.0/16'
      // dockerBridgeCidr: '172.17.0.1/16'
      outboundType: 'loadBalancer'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: false
      //authorizedIPRanges: []
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: false
      }
      kubeDashboard: {
        enabled: true
      }
      azurePolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: omsResourceId
        }
      }
    }
  }
}

resource aksInsights 'Microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: '${aks.name}_AllEvents'
  scope: aks
  properties: {
    workspaceId: omsResourceId

    logs: [
      {
        category: 'kube-apiserver'
        enabled: true
      }
      {
        category: 'kube-audit'
        enabled: true
      }
      {
        category: 'kube-audit-admin'
        enabled: true
      }
      {
        category: 'kube-controller-manager'
        enabled: true
      }
      {
        category: 'kube-scheduler'
        enabled: true
      }
      {
        category: 'cluster-autoscaler'
        enabled: true
      }
      {
        category: 'guard'
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

//Set permissions to omsagent identity on AKS
resource aksPermissionsMonitoringMetrics 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, aks.id, 'Monitoring Metrics Publisher')
  scope: aks
  dependsOn: [
    aks
  ]
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb' //Monitoring Metrics Publisher
    principalId: reference(aks.id, '2020-03-01').addonProfiles.omsagent.identity.objectId
  }
}

output AksResourceId string = aks.id
output AksResourceGroupName string = resourceGroup().name
output AksControlPlaneFQDN string = aks.properties.fqdn
output AksKubeletIdentity string = reference(aks.id, '2020-03-01').identityProfile.kubeletidentity.objectId
output AksOmsAgentIdentity string = reference(aks.id, '2020-03-01').addonProfiles.omsagent.identity.objectId
output AksManagedIdentityId string = aks.identity.principalId
output AksClusterName string = aks.name
