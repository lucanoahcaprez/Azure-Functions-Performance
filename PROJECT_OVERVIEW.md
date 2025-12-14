# Azure Function Performance Bench

This repository compares Azure Function runtimes by invoking example workloads and visualizing latency trends. It has two main parts:

- `functions/`: Language-specific Azure Functions (PowerShell, Node.js, Python, .NET/C#, Java) that expose identical workload parameters.
- `webapp/`: Frontend-only Svelte + Tailwind app for triggering functions, running automated test rounds, and charting results.

## Goal
Give a quick, side‑by‑side look at runtime behavior (CPU/IO/delay) with minimal setup: paste your signed Function URLs, run tests, and review timelines/logs.

## High-level flow
1) Deploy the sample functions for the runtimes you want to measure.  
2) Open the webapp, paste one signed URL per runtime in the setup wizard.  
3) Run manual calls or automatic batches; the UI records durations and renders a combined timeline and trend chart.

## Workloads (shared parameters)
- `workload`: `cpu` | `io` | `delay`
- `iterations` (cpu), `sizeKb` (io), `delayMs` (delay)

All runtimes accept these query parameters and return JSON with runtime, workload, durationMs, timestamp, and echoed request info.
