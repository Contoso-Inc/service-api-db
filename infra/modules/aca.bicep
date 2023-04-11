@description('Name of the aca environment.')
param environmentName string

@description('Location of the aca environment.')
param location string

@description('Tags to add to the resources')
param tags object = {}

@description('log analytics workspace customer id.')
param logAnalyticsWorkspaceCustomerId string

@description('log analytics workspace primary shared key.')
param logAnalyticsWorkspacePrimarySharedKey string

@description('app insights instrumentation key.')
param appInsightsInstrumentationKey string

param acaSubnetId string

resource acaenvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: environmentName
  location: location
  properties: {
    daprAIInstrumentationKey:appInsightsInstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspaceCustomerId
        sharedKey: logAnalyticsWorkspacePrimarySharedKey
      }
    }
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: acaSubnetId
      runtimeSubnetId: acaSubnetId
    }
  }  
}

output id string = acaenvironment.id
output staticip string = acaenvironment.properties.staticIp
output domainname string = acaenvironment.properties.defaultDomain
