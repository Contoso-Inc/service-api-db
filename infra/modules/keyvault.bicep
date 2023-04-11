targetScope = 'resourceGroup'

param keyVaultName string

param enableKeyVaultPrivateDnsZone bool = true

param subnetResourceId string

param location string = resourceGroup().location

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = if (enableKeyVaultPrivateDnsZone) {
  name: split(subnetResourceId, '/')[8]
  scope: resourceGroup(split(subnetResourceId, '/')[4])
}

resource privateDnsZoneKv 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enableKeyVaultPrivateDnsZone) {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  properties: {}
}

//resource privateDnsZoneKvVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enableKeyVaultPrivateDnsZone) {

//}
