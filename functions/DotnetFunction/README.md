# Dotnet Function deployment guide

This guide covers how to run and deploy the .NET Azure Function using Core Tools or the Azure CLI, and explains how it runs in Azure.

## What this function is
- C# Azure Functions app using the .NET isolated worker (Functions v4, .NET 8)
- Sample HTTP trigger in `DotnetFunction.cs` responds to GET/POST
- Local runtime: Azure Functions Core Tools v4
- App settings are configured via `local.settings.json` and Azure App Settings

## Folder layout
```
functions/DotnetFunction/
  DotnetFunction.cs
  Program.cs
  host.json
  local.settings.json
  DotnetFunction.csproj
  NuGet.Config
  Properties/launchSettings.json
```

## Run locally
1) Install prerequisites:
   - .NET SDK 8.x
   - Azure Functions Core Tools v4
2) Configure local settings in `local.settings.json`:
```
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated"
  }
}
```
3) Build and run:
```
dotnet restore
dotnet build
func start
```

## Deploy using Core Tools
1) Publish directly:
```
func azure functionapp publish func-bfh-azfperf-dotnet-test-01 --dotnet-isolated
```

## Deploy using Azure CLI (zip deploy)
1) Publish and package:
```
dotnet publish -c Release
if (Test-Path publish.zip) { Remove-Item publish.zip }
Compress-Archive -Path bin\Release\net8.0\publish\* -DestinationPath publish.zip
```

2) Deploy the zip:
```
az functionapp deployment source config-zip `
  --resource-group <rg-name> `
  --name <app-name> `
  --src publish.zip
```

## Deploy using VS Code (Azure Functions extension)
1) Build the project:
```
dotnet build
```
2) Use the Command Palette:
- `Azure Functions: Deploy to Function App...`
- Select the function app and confirm deployment

## App settings in Azure
- `FUNCTIONS_EXTENSION_VERSION=~4`
- `AzureWebJobsStorage` set to a valid storage connection string
- `WEBSITE_RUN_FROM_PACKAGE=1` (for zip deploy)

## How it works in Azure (background)
- The Functions host starts and reads `host.json` for global settings.
- The .NET isolated worker loads the compiled app and invokes the handler on incoming requests.
- Requests hit `/api/DotnetFunction`, and the response is built in the handler.
- Zip deploy uploads a package to the Function App and the platform mounts it in `wwwroot`.
