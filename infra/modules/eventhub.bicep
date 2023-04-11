targetScope = 'resourceGroup'

@description('Required. Specifies the name of the eventhub namespace.')
param eventHubNamespaceName string = 'asbd-ehn-s01-dz-teamX-01'

@description('Required. The ID of the user assigned managed identity to assigned to the eventhub namespace. Use dedicated zone user identity.')
param userAssignedIdentityResourceId string

@description('Optional. Deploy the Private Dns zone for the Eventhub namespace and integrate it with the subnet virtual network.')
param enableEventHubPrivateDnsZone bool = true

@description('Required. The resource Id of the subnet to deploy the eventhub namespace private endpoint into.')
param subnetResourceId string

@description('Optional. Specifies the location of resources. It picks up Resouce Group\'s  location by default.')
param location string = resourceGroup().location

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = if (enableEventHubPrivateDnsZone) {
  name: split(subnetResourceId, '/')[8]
  scope: resourceGroup(split(subnetResourceId, '/')[4])
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2022-01-01-preview' = {
name: eventHubNamespaceName
location: location
  identity: {
    type: 'UserAssigned'
      userAssignedIdentities: {
        '${userAssignedIdentityResourceId}' : {}
     }
   }
    sku:{
      name: 'Standard'
      tier: 'Standard'
      capacity: 1
    }
    properties:{
      zoneRedundant:false
      isAutoInflateEnabled: false
      minimumTlsVersion: '1.2'
      publicNetworkAccess: 'Disabled'
      disableLocalAuth: false
    }
  }

  resource eventHubNamespaceNetworkRuleSets 'Microsoft.EventHub/namespaces/networkRuleSets@2022-01-01-preview' = {
    name: 'default'
    parent: eventHubNamespace
    properties: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
      trustedServiceAccessEnabled: true
    }
  }

  resource eventHubNamespacePrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
    name: '${eventHubNamespace}-pe'
    location: location
      properties: {
        customNetworkInterfaceName: '${eventHubNamespaceName}-pe'
        privateLinkServiceConnections: [
          {
            name: 'eventhubpls'
            properties: {
              privateLinkServiceId: eventHubNamespace.id
              groupIds:[
                'namespace'               
              ]
            }
          }
        ]
        subnet: {
          id: subnetResourceId
        }
      }
    }

resource privateDnsZoneEventHub 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enableEventHubPrivateDnsZone) {
  name: 'privatelink.servicebus.windows.net'
  location: 'global'
  properties: {}
}

resource privateDnsZoneEhVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'eventHubPrivateDnsZoneLink'
  parent: privateDnsZoneEventHub
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id:virtualNetwork.id
    }
  }
}

resource privateDnsZoneGroupEventHubPrivateEndpoint 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  name: 'eventHubPrivateDnsZoneGroup'
  parent: eventHubNamespacePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'eventHubPrivateDnsZoneConfig'
        properties: {
          privateDnsZoneId: privateDnsZoneEventHub.id
        }
      }
    ]
  }


}




