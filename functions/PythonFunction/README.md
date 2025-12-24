# Python Function deployment guide

This guide covers how to deploy the Python Azure Function using VS Code or the Azure CLI, and explains how it runs in Azure.

## What this function is
- HTTP-triggered function with `authLevel: anonymous`
- Entry point: `PythonFunction/__init__.py`
- Binding config: `PythonFunction/function.json`
- Host settings: `host.json`
- Dependencies: `requirements.txt`

## Folder layout
```
functions/PythonFunction/
  host.json
  local.settings.json
  requirements.txt
  PythonFunction/
    function.json
    __init__.py
```

## Deploy using VS Code
1) Install VS Code extensions:
   - Azure Functions
   - Azure Account
2) Open the folder `functions/PythonFunction`.
3) Sign in to Azure in VS Code.
4) Create or select a Function App:
   - Open the Azure view, then Functions.
   - Click Create Function App in Azure.
   - Choose Python and a Functions v4 runtime.
5) Deploy:
   - Right click the Function App, choose Deploy to Function App.
   - Confirm the prompt to upload the local project.
6) Test:
   - Use the Function URL from the Functions view.
   - No function key is required because `authLevel` is `anonymous`.

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
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4
```

2) Create a deployment zip from this repo:
```
cd functions/PythonFunction
zip -r python.zip host.json requirements.txt PythonFunction
```

3) Deploy the zip:
```
az functionapp deployment source config-zip \
  --resource-group <rg> \
  --name <app> \
  --src python.zip
```

## How it works in Azure (background)
- The Functions host starts and reads `host.json` for global settings.
- Each function is discovered via `PythonFunction/function.json`, which declares the HTTP trigger and output binding.
- The Python worker loads `PythonFunction/__init__.py` and invokes `main` on incoming requests.
- Requests hit the function route; this function uses `route: "{*path}"`, so it matches any path under `/api/`.
- Zip deploy uploads a package to the Function App and the platform extracts it into `wwwroot`.
