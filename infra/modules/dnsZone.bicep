//targetScope = 'resourceGroup'

param acaEnvironmentDefaultDomain string
param acaEnvironmentStaticIP string

param virtualNetworkResourceId string

resource privateDnsZoneAca 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: acaEnvironmentDefaultDomain
  location: 'global'
  properties: {}
}

resource privateDnsZoneacaVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'privateDnsZoneLink'
  parent: privateDnsZoneAca
  location: 'global'
  properties:{
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkResourceId
    }
  }
}

resource privateDnsZone_A 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '*'
  parent: privateDnsZoneAca
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: acaEnvironmentStaticIP
      }
    ]
  }
}

