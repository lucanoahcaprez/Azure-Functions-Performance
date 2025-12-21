targetScope = 'resourceGroup'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Prefix for Function App names; runtime suffixes are appended.')
param namePrefix string = 'azfperf'

@description('Zip package URI for the .NET function app (optional).')
param packageUriDotnet string = 'https://github.com/lucanoahcaprez/Azure-Functions-Performance/releases/latest/download/dotnet.zip'

@description('Zip package URI for the Node.js function app (optional).')
param packageUriNode string = 'https://github.com/lucanoahcaprez/Azure-Functions-Performance/releases/latest/download/node.zip'

@description('Zip package URI for the Python function app (optional).')
param packageUriPython string = 'https://github.com/lucanoahcaprez/Azure-Functions-Performance/releases/latest/download/python.zip'

@description('Zip package URI for the PowerShell function app (optional).')
param packageUriPowerShell string = 'https://github.com/lucanoahcaprez/Azure-Functions-Performance/releases/latest/download/powershell.zip'

@description('Zip package URI for the Java function app (optional).')
param packageUriJava string = 'https://github.com/lucanoahcaprez/Azure-Functions-Performance/releases/latest/download/java.zip'

var storageName = take(toLower('${namePrefix}${uniqueString(resourceGroup().id)}000000000000000000000000'), 24)

var runtimeConfigs = [
  {
    id: 'dotnet'
    suffix: 'dotnet'
    worker: 'dotnet'
    runtimeName: 'dotnet-isolated'
    runtimeVersion: '8.0'
    deployContainerName: take('${toLower(namePrefix)}-dotnet-deploy', 63)
    packageUri: packageUriDotnet
  }
  {
    id: 'node'
    suffix: 'node'
    worker: 'node'
    runtimeName: 'node'
    runtimeVersion: '20'
    deployContainerName: take('${toLower(namePrefix)}-node-deploy', 63)
    packageUri: packageUriNode
  }
  {
    id: 'python'
    suffix: 'python'
    worker: 'python'
    runtimeName: 'python'
    runtimeVersion: '3.11'
    deployContainerName: take('${toLower(namePrefix)}-python-deploy', 63)
    packageUri: packageUriPython
  }
  {
    id: 'powershell'
    suffix: 'powershell'
    worker: 'powershell'
    runtimeName: 'powershell'
    runtimeVersion: '7.4'
    deployContainerName: take('${toLower(namePrefix)}-powershell-deploy', 63)
    packageUri: packageUriPowerShell
  }
  {
    id: 'java'
    suffix: 'java'
    worker: 'java'
    runtimeName: 'java'
    runtimeVersion: '17'
    deployContainerName: take('${toLower(namePrefix)}-java-deploy', 63)
    packageUri: packageUriJava
  }
]

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${namePrefix}-plan'
  location: location
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true
  }
}

var storageKey = listKeys(storage.id, storage.apiVersion).keys[0].value
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storageKey};EndpointSuffix=${environment().suffixes.storage}'
resource deployContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for runtime in runtimeConfigs: {
  name: '${storage.name}/default/${runtime.deployContainerName}'
  properties: {
    publicAccess: 'None'
  }
}]

resource functionApps 'Microsoft.Web/sites@2023-12-01' = [for runtime in runtimeConfigs: {
  name: toLower('${namePrefix}-${runtime.suffix}')
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: plan.id
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
          value: 'https://${storage.name}.blob.${environment().suffixes.storage}/${runtime.deployContainerName}'
          authentication: {
            type: 'StorageAccountConnectionString'
            storageAccountConnectionStringName: 'AzureWebJobsStorage'
          }
        }
      }
    }
    siteConfig: {
      appSettings: concat([
        {
          name: 'AzureWebJobsStorage'
          value: storageConnectionString
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: runtime.packageUri
        }
      ])
    }
  }
}]


output functionAppNames array = [for runtime in runtimeConfigs: toLower('${namePrefix}-${runtime.suffix}')]
