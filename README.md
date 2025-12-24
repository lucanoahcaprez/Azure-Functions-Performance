# Azure Function Performance Bench

This repository compares Azure Function runtimes by invoking example workloads and visualizing latency trends. It has two main parts:

- `functions/`: Language-specific Azure Functions (PowerShell, Node.js, Python, .NET/C#, Java) that expose identical workload parameters.
- `webapp/`: Frontend-only Svelte + Tailwind app for triggering functions, running automated test rounds, and charting results.

## Goal
Give a quick, side-by-side look at runtime behavior (CPU/IO/delay) with minimal setup: paste your signed Function URLs, run tests, and review timelines/logs.

## Prerequisites
- Azure subscription.
- Azure CLI (for deploying resources or zips).
- Optional: Azure Functions Core Tools (for local runs).
- Webapp build: Node.js 20+ and npm/pnpm.
- Java function build: JDK 8+ and Maven (or the Maven wrapper if present).

## High-level flow
1) Deploy the sample functions for the runtimes you want to measure.  
2) Open the webapp, paste one signed URL per runtime in the setup wizard.  
3) Run manual calls or automatic batches; the UI records durations and renders a combined timeline and trend chart.

## Sample page
Live example: https://azfunctionsperformance.apps.lucanoahcaprez.ch/

## Deploy Functions to Azure
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Flucanoahcaprez%2FAzure-Functions-Performance%2Fmain%2Fdeployment%2Fazuredeploy.json)

The template creates one Function App per runtime and can optionally deploy code via zip package URIs. See `deployment/DEPLOYMENT.md` for details.

## Deploy the webapp with Docker
From the repo root:
```sh
docker build -t azfunctionsperformance-webapp ./webapp
docker run --rm -p 8080:80 azfunctionsperformance-webapp
```
Open http://localhost:8080 and add your signed Function URLs in the setup wizard.

## Workloads (shared parameters)
- `workload`: `cpu` | `io` | `delay`
- `iterations` (cpu), `sizeKb` (io), `delayMs` (delay)

All runtimes accept these query parameters and return JSON with runtime, workload, durationMs, timestamp, and echoed request info.
