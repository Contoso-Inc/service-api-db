@description('Name of the vnet.')
param vnetName string
param prefix string

param location string = resourceGroup().location
param acaAcrRegistryName string

var vnetAddressPrefix = '172.16.48.0/21'
var subnetAddressPrefix = '172.16.48.0/23'
var subnetName = 'default'

var pesubnetAddressPrefix = '172.16.50.0/24'
var pesubnetName = 'pesubnet'

resource chompnsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: '${vnetName}-nsg'
  location: location
}
resource pechompnsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: '${vnetName}-pe-nsg'
  location: location
}

resource chompvnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: chompnsg.id
          }
        }
      }
      {
        name: pesubnetName
        properties: {
          addressPrefix: pesubnetAddressPrefix
          networkSecurityGroup: {
            id: pechompnsg.id
          }
        }
      }
    ]
  }
  resource integrationSubnet 'subnets' existing = {
    name: subnetName
  }
  resource peSubnet 'subnets' existing = {
    name: pesubnetName
  }
}

resource privateDnsZoneAcr 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  properties: {
  }
}

resource privateDnsZoneAcrVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'acrPrivateDnsZoneLink'
  parent: privateDnsZoneAcr
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: chompvnet.id
    }
  }
}

resource existingacr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
    name: acaAcrRegistryName
}

resource azureContainerRegistryPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name:'${prefix}-${acaAcrRegistryName}-pe'
  location:location
  properties:{
    customNetworkInterfaceName:'${prefix}-${acaAcrRegistryName}-pe-nic'
    privateLinkServiceConnections:[
      {
        name:'${prefix}-${acaAcrRegistryName}-pe-pls'
        properties: {
          privateLinkServiceId:existingacr.id
          groupIds:[
            'registry'
          ]
        }
      }
    ]
    subnet:{
      id:chompvnet::peSubnet.id
    }
  }
}

resource privateDnsZoneGroupAcrPrivateEndpoint 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  name:'${prefix}-acrPrivateDnsZoneGroup'
  parent:azureContainerRegistryPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
      name: '${prefix}-acrPrivateDnsZoneConfig'
      properties: {
        privateDnsZoneId: privateDnsZoneAcr.id
      }
    }
    ]
  }
}

output acaSubnetId string = chompvnet::integrationSubnet.id
output acaVnetId string = chompvnet.id
