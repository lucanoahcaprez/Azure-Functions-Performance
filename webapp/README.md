# Webapp Guide (Svelte + Tailwind)

Frontend-only UI for triggering the sample Azure Functions, running automated batches, and visualizing latency trends. It is a static site with no backend.

## Structure
- `webapp/src/routes/+page.svelte`: main UI and logic (runtime selection, calls, charts, setup wizard).
- `webapp/src/app.css`: global styling (fonts, gradients, layout).
- `webapp/static/`: static assets copied to the build output.
- `webapp/static/example-functions.json`: optional example URL map used only when enabled via env.
- `webapp/static/.htaccess`: static hosting rules (if used).

## Prerequisites
- Node.js 20+
- npm (or pnpm if you prefer)

## Install & run (dev)
```bash
cd webapp
npm install
npm run dev
```
Open the dev server URL. A setup wizard appears on first launch.

## Build (static)
```bash
cd webapp
npm run build
```
Output is written to `webapp/build/`.

## Configuration wizard
- Paste one signed Azure Function URL per runtime you want to test (Node, Python, PowerShell, .NET, Java).
- Empty entries hide that runtime in the main UI.
- URLs are stored in `localStorage` only.
- Storage key: `functionBench.baseUrls.v2`.

## Environment variables
### `PUBLIC_USE_EXAMPLE_FUNCTIONS`
If set to a truthy value (`1`, `true`, `yes`), the app attempts to load default URLs from `/example-functions.json` when no stored URLs are found.

Where it reads:
- In the app: `import.meta.env.PUBLIC_USE_EXAMPLE_FUNCTIONS`.
- The file must exist at `webapp/static/example-functions.json`.

Expected JSON shape:
```json
{
  "dotnet": "https://<app>.azurewebsites.net/api/DotnetFunction?code=...",
  "node": "https://<app>.azurewebsites.net/api/NodeFunction?code=...",
  "python": "https://<app>.azurewebsites.net/api/PythonFunction?code=...",
  "powershell": "https://<app>.azurewebsites.net/api/PowerShellFunction?code=...",
  "java": "https://<app>.azurewebsites.net/api/JavaFunction?code=..."
}
```
If localStorage already has URLs, those win and the example file is ignored.

## How it works
- Runtime selector picks a configured Function URL and applies query params.
- Workloads: `cpu`, `io`, `delay`.
- Query params appended automatically:
  - `workload=cpu|io|delay`
  - `iterations` (CPU), `sizeKb` (IO), `delayMs` (delay)
- `Call Function`: single request.
- `Test automatically`: runs each configured workload 10 times per runtime.
- Results are recorded with duration, status, and a response snippet (first 240 chars).

## Visuals
- Timeline bars: chronological dots for recent calls.
- Trend chart: line graph of durations vs run index; hover shows runtime, workload, run #, duration.
- Request log: newest-first list with duration bars and status chips.

## Static hosting notes
- The build output is static HTML/CSS/JS and can be served by any static host.
- `.htaccess` in `webapp/static/` is included in the build for Apache-style hosting.

## Security notes
- This app is client-only. All Function URLs are stored in the browser and sent directly from the user’s device.
- Signed Function URLs (`?code=...`) should be treated as secrets; avoid sharing screenshots or logs that include them.

## Troubleshooting
- If a runtime is missing, confirm its URL is set in the wizard or `example-functions.json`.
- If `PUBLIC_USE_EXAMPLE_FUNCTIONS` is set but nothing loads, check that `/example-functions.json` is accessible on your host.
- If calls fail, verify Function App health and keys.
