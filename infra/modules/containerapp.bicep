param location string = resourceGroup().location

@description('Name of the ACA environment')
param acaenvironmentid string

@description('Name of the container app')
param containerappname string

param acrname string

param containerimagename string

param environmentvars array= []

resource containerapp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: containerappname
  location: location
  properties: {
    managedEnvironmentId: acaenvironmentid
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        targetPort: 80
        external: true
      }
      dapr: {
        enabled: true
        appId: containerappname
        appProtocol: 'http'
        appPort: 80
      }
      secrets: [
        {
          name: 'asbdacrs01dzpuma01password'
          value: 'OqPNGjCL72VnWoHfnh3Qf1yamh/z4UZg'
        }
      ]
      registries: [
        {
          server: acrname
          username: 'asbdacrs01dzpuma01'
          passwordSecretRef: 'asbdacrs01dzpuma01password'
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${acrname}/${containerimagename}:latest'
          name: containerimagename
          env: environmentvars
//          command: [
//            'sh', '-c', 'sleep 3600'
//          ]
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                port: 80
                path: '/health/live'
              }
              initialDelaySeconds: 10
              periodSeconds: 5
              timeoutSeconds: 5
            }
            {
              type: 'Readiness'
              httpGet: {
                port: 80
                path: '/health/ready'
              }
              initialDelaySeconds: 10
              periodSeconds: 5
              timeoutSeconds: 5
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
    }
  }
}
