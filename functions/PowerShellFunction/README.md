# PowerShell Function deployment guide

This guide covers how to deploy the PowerShell Azure Function using VS Code or the Azure CLI, and explains how it runs in Azure.

## What this function is
- HTTP-triggered function with `authLevel: function`
- Entry point: `PowerShellFunction/run.ps1`
- Binding config: `PowerShellFunction/function.json`
- Host settings: `host.json`
- Dependencies: `requirements.psd1`

## Folder layout
```
functions/PowerShellFunction/
  host.json
  local.settings.json
  requirements.psd1
  profile.ps1
  PowerShellFunction/
    function.json
    run.ps1
```

## Deploy using VS Code
1) Install VS Code extensions:
   - Azure Functions
   - Azure Account
2) Open the folder `functions/PowerShellFunction`.
3) Sign in to Azure in VS Code.
4) Create or select a Function App:
   - Open the Azure view, then Functions.
   - Click Create Function App in Azure.
   - Choose PowerShell and a Functions v4 runtime.
5) Deploy:
   - Right click the Function App, choose Deploy to Function App.
   - Confirm the prompt to upload the local project.
6) Test:
   - Use the Function URL from the Functions view.
   - It requires a function key (`?code=...`) because `authLevel` is `function`.

## Deploy using Azure CLI (zip deploy)
This uses a zip package similar to what the release workflow builds.

1) Create resources (once):
```
az group create --name <rg> --location <region>
az storage account create --name <storage> --resource-group <rg> --location <region> --sku Standard_LRS
az functionapp create \
  --name <app> \
  --resource-group <rg> \
  --storage-account <storage> \
  --consumption-plan-location <region> \
  --runtime powershell \
  --runtime-version 7.4 \
  --functions-version 4
```

2) Create a deployment zip from this repo:
```
cd functions/PowerShellFunction
zip -r powershell.zip host.json requirements.psd1 profile.ps1 PowerShellFunction
```

3) Deploy the zip:
```
az functionapp deployment source config-zip \
  --resource-group <rg> \
  --name <app> \
  --src powershell.zip
```

## How it works in Azure (background)
- The Functions host starts and reads `host.json` for global settings.
- Each function is discovered via `PowerShellFunction/function.json`, which declares the HTTP trigger and output binding.
- The PowerShell worker loads `PowerShellFunction/run.ps1` and invokes the script on incoming requests.
- Requests hit `/api/PowerShellFunction`, and the response is built in the script.
- Zip deploy uploads a package to the Function App and the platform extracts it into `wwwroot`.
