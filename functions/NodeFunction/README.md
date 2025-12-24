# Node Function deployment guide

This guide covers how to deploy the Node.js Azure Function using VS Code or the Azure CLI, and explains how it runs in Azure.

## What this function is
- HTTP-triggered function with `authLevel: function`
- Entry point: `NodeFunction/index.js`
- Binding config: `NodeFunction/function.json`
- Host settings: `host.json`

## Folder layout
```
functions/NodeFunction/
  host.json
  local.settings.json
  package.json
  NodeFunction/
    function.json
    index.js
```

## Deploy using VS Code
1) Install VS Code extensions:
   - Azure Functions
   - Azure Account
2) Open the folder `functions/NodeFunction`.
3) Sign in to Azure in VS Code.
4) Create or select a Function App:
   - Open the Azure view, then Functions.
   - Click Create Function App in Azure.
   - Choose Node.js and a Functions v4 runtime (LTS Node recommended).
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
  --runtime node \
  --runtime-version 18 \
  --functions-version 4
```

2) Create a deployment zip from this repo:
```
cd functions/NodeFunction
zip -r node.zip host.json package.json NodeFunction
```

3) Deploy the zip:
```
az functionapp deployment source config-zip \
  --resource-group <rg> \
  --name <app> \
  --src node.zip
```

## How it works in Azure (background)
- The Functions host starts and reads `host.json` for global settings.
- Each function is discovered via `NodeFunction/function.json`, which declares the HTTP trigger and output binding.
- The Node.js worker loads `NodeFunction/index.js` and invokes the handler on incoming requests.
- Requests hit `/api/NodeFunction`, and the response is built in the handler.
- Zip deploy uploads a package to the Function App and the platform extracts it into `wwwroot`.
