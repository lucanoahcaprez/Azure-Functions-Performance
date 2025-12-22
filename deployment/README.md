# Azure Functions deployment

This repo ships an ARM/Bicep template that creates one Function App per runtime and deploys each runtime's code from a zip package URI.

## Deploy to Azure (click-to-deploy)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Flucanoahcaprez%2FAzure-Functions-Performance%2Fmain%2Fdeployment%2Fazuredeploy.json)

## What gets created
- 1 storage account
- 1 Consumption plan (Y1, Linux)
- 5 Function Apps: dotnet, node, python, powershell, java

## Deploying code
The template supports optional zip package URIs. Default values point to the latest GitHub release assets produced by the workflow below. If you leave a package URI empty, the Function App is created without code.

## GitHub release packages
A workflow builds zip packages directly from this repo and uploads them as GitHub release assets.

Workflow file: `.github/workflows/release-functions.yml`

How it works:
1) Create a tag like `functions-v1.0.0` and push it.
2) The workflow creates `dotnet.zip`, `node.zip`, `python.zip`, `powershell.zip`, `java.zip` in the release.
3) The deploy button defaults to these URLs:
   - `https://github.com/lucanoahcaprez/Azure-Functions-Performance/releases/latest/download/dotnet.zip`
   - `https://github.com/lucanoahcaprez/Azure-Functions-Performance/releases/latest/download/node.zip`
   - `https://github.com/lucanoahcaprez/Azure-Functions-Performance/releases/latest/download/python.zip`
   - `https://github.com/lucanoahcaprez/Azure-Functions-Performance/releases/latest/download/powershell.zip`
   - `https://github.com/lucanoahcaprez/Azure-Functions-Performance/releases/latest/download/java.zip`

Note: The workflow builds Java with Maven and .NET with `dotnet publish`. The resulting release zips are ready for Flex Consumption.

If you prefer, you can deploy code afterwards using Azure Functions Core Tools:
```sh
func azure functionapp publish <app-name>
```

## Files
- `deployment/main.bicep`: source template
- `deployment/azuredeploy.json`: ARM template used by the deploy button
