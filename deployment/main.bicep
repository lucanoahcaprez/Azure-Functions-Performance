targetScope = 'resourceGroup'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Prefix for Function App names; runtime suffixes are appended.')
param namePrefix string = 'azfbench'

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

var storageName = take(toLower('${namePrefix}${uniqueString(resourceGroup().id)}'), 24)

var runtimeConfigs = [
  {
    id: 'dotnet'
    suffix: 'dotnet'
    worker: 'dotnet'
    packageUri: packageUriDotnet
  }
  {
    id: 'node'
    suffix: 'node'
    worker: 'node'
    packageUri: packageUriNode
  }
  {
    id: 'python'
    suffix: 'python'
    worker: 'python'
    packageUri: packageUriPython
  }
  {
    id: 'powershell'
    suffix: 'powershell'
    worker: 'powershell'
    packageUri: packageUriPowerShell
  }
  {
    id: 'java'
    suffix: 'java'
    worker: 'java'
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

resource plan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${namePrefix}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

var storageKey = listKeys(storage.id, storage.apiVersion).keys[0].value
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storageKey};EndpointSuffix=${environment().suffixes.storage}'

resource functionApps 'Microsoft.Web/sites@2022-09-01' = [for runtime in runtimeConfigs: {
  name: toLower('${namePrefix}-${runtime.suffix}')
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
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
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: runtime.worker
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: take('${toLower(namePrefix)}-${runtime.suffix}-content', 63)
        }
      ], runtime.packageUri != '' ? [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: runtime.packageUri
        }
      ] : [])
    }
  }
}]

output functionAppNames array = [for runtime in runtimeConfigs: toLower('${namePrefix}-${runtime.suffix}')]
