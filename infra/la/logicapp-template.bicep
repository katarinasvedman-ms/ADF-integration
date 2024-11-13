@description('The datacenter to use for the deployment.')
param location string
param environmentName string
param projectName string
param logicAppName string
param appServicePlanName string

@minLength(3)
@maxLength(24)
param storageName string
param kind string = 'StorageV2'
param skuName string = 'Standard_LRS'
param skuTier string = 'Standard'

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: kind
  name: storageName
  location: location
  tags: {
    Environment: environmentName
    Project: projectName
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: appServicePlanName
  location: location
  tags: {
    Environment: environmentName
    Project: projectName
  }
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
  kind: 'windows'
}

resource logicApp 'Microsoft.Web/sites@2021-02-01' = {
  name: logicAppName
  location: location
  kind: 'workflowapp,functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      netFrameworkVersion: 'v4.6'
      appSettings: [
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.0.0, 2.0.0)'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
    }
  }
  tags: {
    Environment: environmentName
    Project: projectName
  }
  dependsOn: [
    appServicePlan
    storageAccount
  ]
}
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, logicApp.id, 'Storage Blob Data Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor role
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
    scope: resourceGroup().id
  }
}
