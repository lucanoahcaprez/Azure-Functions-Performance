targetScope = 'resourceGroup'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Prefix for Function App names; runtime suffixes are appended.')
param namePrefix string = 'azfperf'

@description('Storage account name (max 24 chars).')
param storageAccountName string = toLower(take(format('st{0}', uniqueString(resourceGroup().id)), 24))

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
@description('Storage account SKU.')
param storageAccountType string = 'Standard_LRS'

@description('Log Analytics workspace name for Application Insights.')
param logAnalyticsWorkspaceName string = 'logs-azfperf-lab-test'

@description('Subscription ID for the Log Analytics Workspace.')
param subscriptionId string = subscription().subscriptionId

@description('Resource group of the Log Analytics Workspace.')
param resourceGroupName string = resourceGroup().name

@description('Host function key name used for all function apps.')
param hostFunctionKeyName string = 'defaultkey'

@description('Host function key value used for all function apps.')
@secure()
param hostFunctionKeyValue string

var workspaceResourceId = format('/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OperationalInsights/workspaces/{2}', subscriptionId, resourceGroupName, logAnalyticsWorkspaceName)

var flexRuntimes = [
  {
    suffix: 'powershell'
    runtimeName: 'powerShell'
    runtimeVersion: '7.4'
  }
  {
    suffix: 'dotnet'
    runtimeName: 'dotnet-isolated'
    runtimeVersion: '8.0'
  }
  {
    suffix: 'java'
    runtimeName: 'java'
    runtimeVersion: '17'
  }
  {
    suffix: 'node'
    runtimeName: 'node'
    runtimeVersion: '20'
  }
  {
    suffix: 'python'
    runtimeName: 'python'
    runtimeVersion: '3.11'
  }
]

var deploymentStorageContainerName = toLower(format('app-packages-{0}', take(storageAccountName, 20)))

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: '${storageAccountName}/default'
  dependsOn: [
    storage
  ]
  properties: {
    deleteRetentionPolicy: {}
  }
}

resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${storageAccountName}/default/${deploymentStorageContainerName}'
  dependsOn: [
    blobServices
  ]
  properties: {
    publicAccess: 'None'
  }
}

resource plans 'Microsoft.Web/serverfarms@2023-12-01' = [for runtime in flexRuntimes: {
  name: format('{0}-plan-{1}-flex', namePrefix, runtime.suffix)
  location: location
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true
  }
}]

resource appInsights 'Microsoft.Insights/components@2020-02-02' = [for runtime in flexRuntimes: {
  name: format('{0}-{1}-ai', namePrefix, runtime.suffix)
  location: location
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites', toLower(format('{0}-{1}', namePrefix, runtime.suffix)))}': 'Resource'
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceResourceId
  }
}]

resource functionApps 'Microsoft.Web/sites@2024-04-01' = [for (runtime, index) in flexRuntimes: {
  name: toLower(format('{0}-{1}', namePrefix, runtime.suffix))
  location: location
  kind: 'functionapp,linux'
  dependsOn: [
    appInsights[index]
    plans[index]
    storage
    blobServices
    deploymentContainer
  ]
  properties: {
    serverFarmId: plans[index].id
    httpsOnly: true
    functionAppConfig: {
      runtime: {
        name: runtime.runtimeName
        version: runtime.runtimeVersion
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 2048
        maximumInstanceCount: 40
      }
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${reference(storage.id, '2023-05-01').primaryEndpoints.blob}${deploymentStorageContainerName}'
          authentication: {
            type: 'StorageAccountConnectionString'
            storageAccountConnectionStringName: 'AzureWebJobsStorage'
          }
        }
      }
    }
    siteConfig: {
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: reference(appInsights[index].id, '2020-02-02').ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: format('DefaultEndpointsProtocol=https;AccountName={0};EndpointSuffix={1};AccountKey={2}', storageAccountName, environment().suffixes.storage, listKeys(storage.id, '2021-09-01').keys[0].value)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
    }
  }
}]

resource hostKeys 'Microsoft.Web/sites/host/functionKeys@2023-12-01' = [for (runtime, index) in flexRuntimes: {
  name: '${toLower(format('{0}-{1}', namePrefix, runtime.suffix))}/default/${hostFunctionKeyName}'
  dependsOn: [
    functionApps[index]
  ]
  properties: {
    name: hostFunctionKeyName
    value: hostFunctionKeyValue
  }
}]

output functionAppNames array = [
  toLower(format('{0}-powershell', namePrefix))
  toLower(format('{0}-dotnet', namePrefix))
  toLower(format('{0}-java', namePrefix))
  toLower(format('{0}-node', namePrefix))
  toLower(format('{0}-python', namePrefix))
]

output appInsightsNames array = [
  format('{0}-powershell-ai', namePrefix)
  format('{0}-dotnet-ai', namePrefix)
  format('{0}-java-ai', namePrefix)
  format('{0}-node-ai', namePrefix)
  format('{0}-python-ai', namePrefix)
]
