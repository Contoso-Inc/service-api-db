// Parameters
@minLength(2)
@maxLength(10)
@description('Prefix for all resource names.')
param prefix string = 'cnt-srv'

@allowed([
  'westus'
  'westus3'
])
@description('Azure region used for the deployment of all resources.')
param location string = 'westus'

@description('Set of tags to apply to all resources.')
param tags object = {}

param acrname string = 'acrsntsrv'

/*
  1. Create log analytics workspace
  2. Create app insights associate with log analytics workspace created in step 1
  3. Create ACA environment
*/


module loganalyticsworkspace 'modules/logAnalyticsworkspace.bicep' = { 
  name: '${prefix}-law-deployment'
  params: {
    logAnalyticsWorkspaceName: '${prefix}-law'
    location: location
    tags: tags
  }
}

module appinsights 'modules/applicationinsights.bicep' = { 
  name: '${prefix}-ai-deployment'
  params: {
    applicationInsightsName: '${prefix}-ai'
    location: location
    tags: tags
    loganalyticsWorkspaceId: loganalyticsworkspace.outputs.logAnalyticsWorkspaceId
  }
}

module network 'modules/networking.bicep' = {
  name: '${prefix}-networking-deployment'
  params: {
    vnetName: '${prefix}-vnet'
    location: location
    acaAcrRegistryName:acrname
    prefix:prefix
  }
}

module aca 'modules/aca.bicep' = { 
  name: '${prefix}-aca-deployment'
  params: {
    environmentName: '${prefix}-aca'
    location: location
    tags: tags
    logAnalyticsWorkspaceCustomerId: loganalyticsworkspace.outputs.customerId
    logAnalyticsWorkspacePrimarySharedKey: loganalyticsworkspace.outputs.sharedKey
    appInsightsInstrumentationKey: appinsights.outputs.instrumentationKey
    acaSubnetId: network.outputs.acaSubnetId
  }
}

module acaPrivateDnsZone 'modules/dnsZone.bicep' = {
  name: '${prefix}-acaPrivateDnsZone-deployment'
  params: {
    virtualNetworkResourceId: network.outputs.acaVnetId
    acaEnvironmentDefaultDomain: aca.outputs.domainname
    acaEnvironmentStaticIP: aca.outputs.staticip
  }
}

var apinames = ['ingress', 'api1', 'api2', 'api3']

module apis 'modules/containerapp.bicep' = [ for apiname in apinames: {
  name: '${apiname}-deployment'
  params: {
    location: location
    acaenvironmentid: aca.outputs.id
    containerappname: apiname
    containerimagename: 'webapi'
    acrname: '${acrname}.azurecr.io'
    environmentvars: [
      {
        name: 'ApiName'
        value: apiname
      }
      {
        name: 'ReturnErrors'
        value: 'false'
      }
      {
        name: 'ApiHostName'
        value: 'localhost:3500/v1.0/invoke/{{${apiname}}}/method'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appinsights.outputs.connectionString
      }
      {
        name: 'SERVICENAMESPACE'
        value: 'ContosoInc'
      }
      {
        name: 'SERVICEVERSION'
        value: '1.0.0'
      }
    ]
  }
}]
