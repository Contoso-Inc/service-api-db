@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object = {}

@description('Application Insights resource name')
param applicationInsightsName string

@description('Log Analytics workspace resource ID')
param loganalyticsWorkspaceId string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    WorkspaceResourceId:loganalyticsWorkspaceId
    Application_Type: 'web'    
  }
}

output applicationInsightsId string = applicationInsights.id
output instrumentationKey string = applicationInsights.properties.InstrumentationKey
output connectionString string = applicationInsights.properties.ConnectionString
