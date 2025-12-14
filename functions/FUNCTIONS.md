# Functions Guide

This folder contains Azure Functions that implement the same workloads across multiple runtimes. Each function is HTTP-triggered (`authLevel: function`) and responds to GET/POST.

## Runtimes included
- PowerShell: `functions/PowerShellFunction/run.ps1`
- Node.js: `functions/NodeFunction/index.js`
- Python: `functions/PythonFunction/__init__.py`
- .NET (C# script): `functions/DotnetFunction/run.csx`
- Java: `functions/JavaFunction/Function.java` (build with the standard Maven Azure Functions template; `function.json` is generated at build)

## Shared query parameters
- `workload`: `cpu` | `io` | `delay`
- `iterations`: integer, CPU workload loop count (default 250000+)
- `sizeKb`: integer, IO workload size in kilobytes (default 128+)
- `delayMs`: integer, delay in milliseconds for `delay` workload

## Workload behaviors
- CPU: math-heavy loop (sqrt/log) to stress CPU.
- IO: write/read a temp file of `sizeKb`.
- Delay: waits for `delayMs`.

## Response shape (all runtimes)
```json
{
  "message": "<runtime> example function",
  "runtime": "node|python|powershell|dotnet|java",
  "workload": "cpu|io|delay|none",
  "iterations": 250000,
  "sizeKb": 128,
  "delayMs": 300,
  "durationMs": 123.45,
  "timestamp": "2025-01-01T00:00:00Z",
  "requestData": {
    "query": { "...": "..." },
    "method": "GET"
  }
}
```

## Running locally
1) Install the Azure Functions Core Tools.  
2) From `functions/`, run `func start`.  
3) Use the printed URLs with `?code=...` in the webapp setup wizard.

## Deploying
Deploy each runtime to an Azure Function App or a single multi-runtime app as needed. Keep the route names:
- PowerShell: `/api/PowerShellFunction`
- Node: `/api/NodeFunction`
- Python: `/api/PythonFunction`
- .NET: `/api/DotnetFunction`
- Java: `/api/JavaFunction`
