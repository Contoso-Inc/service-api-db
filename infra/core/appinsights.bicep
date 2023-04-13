param resourceToken string
param location string
param tags object
param logAnalyticsWorkspaceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${resourceToken}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

output APPINSIGHTS_INSTRUMENTATIONKEY string = appInsights.properties.InstrumentationKey
output APPINSIGHTS_CONNECTION_STRING string = appInsights.properties.ConnectionString
