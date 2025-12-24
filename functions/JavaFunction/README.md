# Java Function deployment guide

This guide covers how to deploy the Java Azure Function using VS Code or the Azure CLI, and explains how it runs in Azure.

## What this function is
- HTTP-triggered function with `authLevel: function`
- Entry point: `src/main/java/com/example/Function.java`
- Build tool: Maven (`pom.xml`)
- Host settings: `host.json` is generated during the build

## Folder layout
```
functions/JavaFunction/
  pom.xml
  src/
    main/java/com/example/Function.java
  target/
    azure-functions/<function-app-name>/
```

## Deploy using VS Code
1) Install VS Code extensions:
   - Azure Functions
   - Azure Account
2) Open the folder `functions/JavaFunction`.
3) Sign in to Azure in VS Code.
4) Build:
   - Run `mvn clean package`.
5) Deploy:
   - Open the Azure view, then Functions.
   - Right click the Function App, choose Deploy to Function App.
   - Select the zip in `target/azure-functions/<function-app-name>/`.
6) Test:
   - Use the Function URL from the Functions view.
   - It requires a function key (`?code=...`) because `authLevel` is `function`.

## Deploy using Azure CLI (zip deploy)
1) Create resources (once):
```
az group create --name <rg> --location <region>
az storage account create --name <storage> --resource-group <rg> --location <region> --sku Standard_LRS
az functionapp create \
  --name <app> \
  --resource-group <rg> \
  --storage-account <storage> \
  --consumption-plan-location <region> \
  --runtime java \
  --runtime-version 17 \
  --functions-version 4
```

2) Build and deploy:
```
cd functions/JavaFunction
mvn clean package
az functionapp deployment source config-zip \
  --resource-group <rg> \
  --name <app> \
  --src target/azure-functions/<app>/<app>.zip
```

## How it works in Azure (background)
- The Functions host starts and reads `host.json` for global settings.
- The Java function metadata is generated during `mvn clean package` into `target/azure-functions/<app>/`.
- The Java worker loads the generated artifact and invokes the handler on incoming requests.
- Requests hit `/api/JavaFunction`, and the response is built in the handler.
- Zip deploy uploads a package to the Function App and the platform extracts it into `wwwroot`.
