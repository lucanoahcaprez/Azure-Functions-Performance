# Webapp Guide (Svelte + Tailwind)

Frontend-only app for triggering the sample Azure Functions, running automated batches, and visualizing latency trends.

## Setup
```bash
cd webapp
npm install
npm run dev
```
Open the dev server URL in your browser. A setup wizard appears on first launch.

## Configuration wizard
- Paste one signed Azure Function URL per runtime you want to test (Node, Python, PowerShell, .NET, Java).  
- Empty entries hide that runtime in the main UI.  
- URLs are stored in `localStorage` only.

## How it works
- Main selectors: choose runtime and workload (`cpu`, `io`, `delay`). Workloads are applied via query params to the single runtime URL.  
- `Call Function`: fires a single request.  
- `Test automatically`: runs each configured workload 10 times in parallel per runtime (30 calls per runtime).  
- Results are recorded with duration, status, and response snippet.

## Visuals
- Timeline bars: chronological dots for recent calls.  
- Trend chart: line graph of durations vs run index, one line per runtime; hover shows runtime, workload, run #, duration.  
- Request log: newest-first list with duration bars and status chips.

## Notes
- Frontend only; no backend.  
- Signed Function URLs (`?code=...`) must be provided by you.  
- All styling via Tailwind; fonts and gradients defined in `src/app.css`.
