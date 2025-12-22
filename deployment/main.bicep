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
    linuxFxVersion: 'DOTNET|8.0'
  }
  {
    id: 'node'
    suffix: 'node'
    worker: 'node'
    runtimeName: 'node'
    runtimeVersion: '20'
    deployContainerName: take('${toLower(namePrefix)}-node-deploy', 63)
    packageUri: packageUriNode
    linuxFxVersion: 'NODE|20'
  }
  {
    id: 'python'
    suffix: 'python'
    worker: 'python'
    runtimeName: 'python'
    runtimeVersion: '3.11'
    deployContainerName: take('${toLower(namePrefix)}-python-deploy', 63)
    packageUri: packageUriPython
    linuxFxVersion: 'PYTHON|3.11'
  }
  {
    id: 'powershell'
    suffix: 'powershell'
    worker: 'powershell'
    runtimeName: 'powershell'
    runtimeVersion: '7.4'
    deployContainerName: take('${toLower(namePrefix)}-powershell-deploy', 63)
    packageUri: packageUriPowerShell
    linuxFxVersion: 'POWERSHELL|7.2'
  }
  {
    id: 'java'
    suffix: 'java'
    worker: 'java'
    runtimeName: 'java'
    runtimeVersion: '17'
    deployContainerName: take('${toLower(namePrefix)}-java-deploy', 63)
    packageUri: packageUriJava
    linuxFxVersion: 'JAVA|17'
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
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

var storageKey = listKeys(storage.id, storage.apiVersion).keys[0].value
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storageKey};EndpointSuffix=${environment().suffixes.storage}'

resource functionApps 'Microsoft.Web/sites@2023-12-01' = [for runtime in runtimeConfigs: {
  name: toLower('${namePrefix}-${runtime.suffix}')
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: runtime.linuxFxVersion
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
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: runtime.packageUri
        }
      ])
    }
  }
}]


output functionAppNames array = [for runtime in runtimeConfigs: toLower('${namePrefix}-${runtime.suffix}')]
