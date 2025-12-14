<script>
  import { onMount } from 'svelte';

  const STORAGE_KEY = 'functionBench.baseUrls.v2';

  const runtimeOptions = [
    {
      id: 'dotnet',
      name: '.NET',
      accent: 'from-sky-400 to-blue-500',
      placeholder: 'https://<dotnet-app>.azurewebsites.net/api/DotnetFunction?code=YOUR_CODE',
      workloads: [
        { id: 'cpu', name: 'CPU intensive', description: 'Floating-point loop to stress compute.', params: { iterations: '300000' } },
        { id: 'io', name: 'IO heavy', description: 'Temp file write/read to stress IO.', params: { sizeKb: '256' } },
        { id: 'delay', name: 'Delay', description: 'Simple wait to observe cold starts.', params: { delayMs: '300' } },
      ],
    },
    {
      id: 'node',
      name: 'Node.js',
      accent: 'from-emerald-400 to-cyan-400',
      placeholder: 'https://<node-app>.azurewebsites.net/api/NodeFunction?code=YOUR_CODE',
      workloads: [
        { id: 'cpu', name: 'CPU intensive', description: 'Math loop to exercise the event loop.', params: { iterations: '300000' } },
        { id: 'io', name: 'IO heavy', description: 'Temp file write/read round-trip.', params: { sizeKb: '256' } },
        { id: 'delay', name: 'Delay', description: 'Timeout-driven delay.', params: { delayMs: '300' } },
      ],
    },
    {
      id: 'python',
      name: 'Python',
      accent: 'from-amber-400 to-lime-400',
      placeholder: 'https://<python-app>.azurewebsites.net/api/PythonFunction?code=YOUR_CODE',
      workloads: [
        { id: 'cpu', name: 'CPU intensive', description: 'Math heavy loop to stress CPU.', params: { iterations: '300000' } },
        { id: 'io', name: 'IO heavy', description: 'Temp file write/read round-trip.', params: { sizeKb: '256' } },
        { id: 'delay', name: 'Delay', description: 'Sleep-based delay.', params: { delayMs: '300' } },
      ],
    },
    {
      id: 'powershell',
      name: 'PowerShell',
      accent: 'from-pink-400 to-rose-500',
      placeholder: 'https://<ps-app>.azurewebsites.net/api/PowerShellFunction?code=YOUR_CODE',
      workloads: [
        { id: 'cpu', name: 'CPU intensive', description: 'PowerShell math loop workload.', params: { iterations: '300000' } },
        { id: 'io', name: 'IO heavy', description: 'Temp file IO round-trip.', params: { sizeKb: '256' } },
        { id: 'delay', name: 'Delay', description: 'Sleep-based delay.', params: { delayMs: '300' } },
      ],
    },
    {
      id: 'java',
      name: 'Java',
      accent: 'from-orange-400 to-amber-500',
      placeholder: 'https://<java-app>.azurewebsites.net/api/JavaFunction?code=YOUR_CODE',
      workloads: [
        { id: 'cpu', name: 'CPU intensive', description: 'Math-heavy loop.', params: { iterations: '300000' } },
        { id: 'io', name: 'IO heavy', description: 'Temp file write/read.', params: { sizeKb: '256' } },
        { id: 'delay', name: 'Delay', description: 'Sleep-based delay.', params: { delayMs: '300' } },
      ],
    },
  ];

  let selectedRuntimeId = '';
  let selectedWorkloadId = '';
  let urlMap = {};
  let isLoading = false;
  let isAutoLoading = false;
  let message = '';
  let error = '';
  let recentRequests = [];
  let showConfig = false;
  let wizardUrls = {};
  let wizardError = '';
  let hasBootstrapped = false;
  let configuredRuntimes = [];
  let hoveredPoint = null;

  const loadStoredUrls = () => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      const parsed = JSON.parse(raw);
      return parsed && typeof parsed === 'object' ? parsed : null;
    } catch (err) {
      console.warn('Failed to parse stored URLs', err);
      return null;
    }
  };

  const persistUrls = (map) => {
    urlMap = map;
    if (!hasBootstrapped) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(map));
    } catch (err) {
      console.warn('Persist failed', err);
    }
  };

  const buildWizardDefaults = () => {
    const draft = { ...urlMap };
    runtimeOptions.forEach((runtime) => {
      if (!draft[runtime.id]) {
        draft[runtime.id] = '';
      }
    });
    return draft;
  };

  onMount(() => {
    const stored = loadStoredUrls();
    if (stored) {
      urlMap = stored;
    }
    wizardUrls = buildWizardDefaults();
    hasBootstrapped = true;
    const configured = runtimeOptions.filter((r) => (urlMap[r.id] ?? '').trim());
    if (!configured.find((r) => r.id === selectedRuntimeId)) {
      selectedRuntimeId = configured[0]?.id ?? '';
      selectedWorkloadId = configured[0]?.workloads[0]?.id ?? '';
    }
    showConfig = configured.length === 0;
  });

  $: configuredRuntimes = runtimeOptions.filter((r) => (urlMap[r.id] ?? '').trim());

  $: if (configuredRuntimes.length === 0 && hasBootstrapped) {
    showConfig = true;
  }

  $: if (!configuredRuntimes.find((r) => r.id === selectedRuntimeId)) {
    selectedRuntimeId = configuredRuntimes[0]?.id ?? '';
  }
  $: selectedRuntime = configuredRuntimes.find((r) => r.id === selectedRuntimeId);

  $: if (selectedRuntime && !selectedRuntime.workloads.find((w) => w.id === selectedWorkloadId)) {
    selectedWorkloadId = selectedRuntime.workloads[0]?.id ?? '';
  }
  $: selectedWorkload = selectedRuntime?.workloads.find((w) => w.id === selectedWorkloadId);

  const appendParams = (base, params) => {
    try {
      const u = new URL(base);
      Object.entries(params).forEach(([k, v]) => u.searchParams.set(k, v));
      return u.toString();
    } catch {
      const qs = new URLSearchParams(params).toString();
      return base + (base.includes('?') ? '&' : '?') + qs;
    }
  };

  $: currentBaseUrl = (selectedRuntime && urlMap[selectedRuntime.id]?.trim()) || '';
  $: currentUrl =
    selectedRuntime && selectedWorkload && currentBaseUrl
      ? appendParams(currentBaseUrl, { workload: selectedWorkload.id, ...(selectedWorkload.params ?? {}) })
      : '';

  $: maxDuration = recentRequests.reduce((acc, req) => Math.max(acc, req.durationMs ?? 0), 0);
  $: timelineRequests = [...recentRequests].sort((a, b) => a.timestamp - b.timestamp);
  $: minTs = timelineRequests[0]?.timestamp ?? Date.now();
  $: maxTs = timelineRequests.at(-1)?.timestamp ?? minTs + 1;
  $: span = Math.max(1, maxTs - minTs);
  $: seriesData = (() => {
    const grouped = new Map();
    timelineRequests.forEach((req) => {
      if (!req.runtimeId) return;
      const arr = grouped.get(req.runtimeId) ?? [];
      arr.push(req);
      grouped.set(req.runtimeId, arr);
    });

    const maxPoints = Math.max(0, ...Array.from(grouped.values()).map((arr) => arr.length));
    const maxVal = Math.max(1, ...Array.from(grouped.values()).flat().map((p) => p.durationMs ?? 0));
    const width = 520;
    const height = 180;
    const pad = 16;

    const color = (id) =>
      ({
        dotnet: '#38bdf8',
        node: '#22d3ee',
        python: '#a3e635',
        powershell: '#f472b6',
        java: '#fb923c',
      }[id] ?? '#67e8f9');

    const series = Array.from(grouped.entries()).map(([runtimeId, entries]) => {
      const points = entries.map((req, idx) => {
        const denom = Math.max(1, entries.length - 1);
        const x = pad + (idx / denom) * (width - 2 * pad);
        const y = height - pad - ((req.durationMs ?? 0) / maxVal) * (height - 2 * pad);
        return {
          x,
          y,
          duration: req.durationMs ?? 0,
          runtimeName: req.runtimeName,
          workloadName: req.workloadName ?? 'N/A',
          runIndex: idx + 1,
        };
      });

      const path = points.map((p) => `${p.x},${p.y}`).join(' ');

      return {
        runtimeId,
        runtimeName: runtimeOptions.find((r) => r.id === runtimeId)?.name ?? runtimeId,
        color: color(runtimeId),
        path,
        points,
      };
    });

    return {
      width,
      height,
      pad,
      maxVal,
      series,
      maxPoints,
    };
  })();

  const formatDuration = (ms) => `${ms.toFixed(1)} ms`;
  const formatTime = (ts) => new Date(ts).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });

  function positionFor(ts) {
    if (span === 0) return 0;
    return ((ts - minTs) / span) * 100;
  }

  function relativeDurationWidth(durationMs) {
    if (!maxDuration) return 35;
    return Math.max(12, (durationMs / maxDuration) * 100);
  }

  async function performCall(runtime, workload, url) {
    const startedAt = Date.now();
    const perfStart = performance.now();
    let durationMs = 0;
    let bodySnippet = '';
    let status = 'ERR';
    let ok = false;

    try {
      const res = await fetch(url, { method: 'GET' });
      durationMs = performance.now() - perfStart;
      status = res.status;
      ok = res.ok;
      bodySnippet = (await res.text()).slice(0, 240);
    } catch (err) {
      durationMs = performance.now() - perfStart;
      bodySnippet = err?.message ?? 'Request failed';
    } finally {
      recentRequests = [
        {
          id: crypto.randomUUID?.() ?? `${startedAt}-${Math.random()}`,
          runtimeId: runtime.id,
          runtimeName: runtime.name,
          workloadId: workload.id,
          workloadName: workload.name,
          timestamp: startedAt,
          durationMs,
          status,
          ok,
          url,
          bodySnippet,
        },
        ...recentRequests,
      ].slice(0, 32);
    }
    return { ok, status, durationMs };
  }

  async function runFunction() {
    if (!selectedRuntime || !selectedWorkload) {
      error = 'Pick a runtime and workload first.';
      return;
    }
    if (!currentUrl || currentUrl.includes('YOUR_CODE')) {
      error = 'Configure a valid signed Azure Function URL in the setup dialog first.';
      showConfig = true;
      return;
    }

    message = '';
    error = '';
    isLoading = true;
    const result = await performCall(selectedRuntime, selectedWorkload, currentUrl);
    message = result.ok ? 'Request completed' : `Request returned status ${result.status}`;
    if (!result.ok && !error) {
      error = 'Request failed. Check the URL and network.';
    }
    isLoading = false;
  }

  async function runAutomaticTests() {
    if (!configuredRuntimes.length) {
      error = 'Add at least one runtime URL first.';
      showConfig = true;
      return;
    }

    const runsPerWorkload = 10;
    const tasks = [];
    configuredRuntimes.forEach((runtime) => {
      const base = (urlMap[runtime.id] ?? '').trim();
      if (!base) return;
      runtime.workloads.forEach((workload) => {
        for (let i = 0; i < runsPerWorkload; i++) {
          const url = appendParams(base, { workload: workload.id, ...(workload.params ?? {}) });
          tasks.push({ runtime, workload, url });
        }
      });
    });

    if (!tasks.length) {
      error = 'No workloads available to test.';
      return;
    }

    message = '';
    error = '';
    isAutoLoading = true;

    const results = await Promise.all(tasks.map(async (t) => performCall(t.runtime, t.workload, t.url)));

    const success = results.filter((r) => r.ok).length;
    message = `Auto test finished: ${success}/${tasks.length} OK across ${configuredRuntimes.length} runtime(s), ${runsPerWorkload} runs per workload.`;
    if (success !== tasks.length) {
      error = 'Some requests failed. Check the URLs or Function availability.';
    }
    isAutoLoading = false;
  }

  function clearHistory() {
    recentRequests = [];
  }

  function openWizard() {
    wizardError = '';
    wizardUrls = buildWizardDefaults();
    showConfig = true;
  }

  function updateWizardUrl(runtimeId, value) {
    wizardUrls = {
      ...wizardUrls,
      [runtimeId]: value,
    };
  }

  function saveWizard() {
    const sanitized = {};
    runtimeOptions.forEach((runtime) => {
      sanitized[runtime.id] = (wizardUrls[runtime.id] ?? '').trim();
    });

    const configuredIds = Object.entries(sanitized)
      .filter(([, v]) => v.length > 0)
      .map(([k]) => k);

    if (configuredIds.length === 0) {
      wizardError = 'Add at least one Function URL.';
      return;
    }

    wizardError = '';
    persistUrls(sanitized);

    const configured = runtimeOptions.filter((r) => (sanitized[r.id] ?? '').trim());
    if (!configured.find((r) => r.id === selectedRuntimeId)) {
      selectedRuntimeId = configured[0]?.id ?? '';
      selectedWorkloadId = configured[0]?.workloads[0]?.id ?? '';
    }

    showConfig = false;
    message = 'Saved URLs';
  }
</script>

<svelte:head>
  <title>Azure Function Performance Bench</title>
</svelte:head>

<main class="text-slate-100 px-4 py-8 md:py-12">
  <div class="max-w-6xl mx-auto space-y-8">
    <section class="glass-panel grid-bg rounded-3xl p-6 md:p-8">
      <div class="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
        <div class="space-y-2">
          <p class="text-xs uppercase tracking-[0.25em] text-slate-400">Azure Function performance</p>
          <h1 class="text-3xl md:text-4xl font-semibold font-display tracking-tight">Runtime latency compare</h1>
          <p class="text-slate-300 max-w-2xl">
            Test .NET, Node.js, Python, PowerShell, and Java workloads side by side. Enter one signed Function URL per runtime, then switch
            workloads via query params automatically.
          </p>
        </div>
        <div class="glass-panel rounded-2xl p-4 border border-cyan-400/30 shadow-neon space-y-1">
          <p class="text-sm text-slate-300">Configuration</p>
          <div class={`text-2xl font-semibold ${configuredRuntimes.length ? 'text-emerald-300' : 'text-amber-200'}`}>
            {configuredRuntimes.length ? `${configuredRuntimes.length} runtime(s) set` : 'Add URLs'}
          </div>
          <p class="text-xs text-slate-400 mt-1">Stored locally in your browser</p>
        </div>
      </div>
    </section>

    <section class="grid gap-6 lg:grid-cols-[1.15fr_0.85fr]">
      <div class="glass-panel rounded-3xl p-6 md:p-7 space-y-6">
        <div class="flex items-center justify-between gap-4">
          <div>
            <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Test setup</p>
            <h2 class="text-xl font-display font-semibold">Choose runtime & workload</h2>
          </div>
          <div class="flex items-center gap-2">
            <button
              class="px-3 py-2 rounded-xl border border-cyan-400/40 bg-cyan-400/10 text-cyan-100 text-sm hover:shadow-neon transition"
              on:click={openWizard}
            >
              {configuredRuntimes.length ? 'Edit URLs' : 'Set URLs'}
            </button>
            <span class="px-3 py-1 rounded-full bg-emerald-500/15 text-emerald-300 text-xs border border-emerald-400/30">
              Frontend only
            </span>
          </div>
        </div>

        {#if configuredRuntimes.length === 0}
          <div class="rounded-2xl border border-dashed border-white/10 bg-white/5 p-5 text-sm text-slate-300">
            Add at least one runtime URL in the setup dialog to start testing.
          </div>
        {:else}
          <div class="space-y-3">
            <p class="text-sm text-slate-300">Runtime</p>
            <div class="flex flex-wrap gap-3">
              {#each configuredRuntimes as runtime}
                <button
                  class={`px-4 py-2 rounded-xl border transition-all duration-200 text-sm font-semibold ${
                    selectedRuntimeId === runtime.id
                      ? 'border-cyan-400/70 bg-cyan-400/10 text-cyan-100 shadow-neon'
                      : 'border-white/10 bg-white/5 text-slate-200 hover:border-cyan-400/40 hover:text-cyan-100'
                  }`}
                  on:click={() => (selectedRuntimeId = runtime.id)}
                >
                  {runtime.name}
                </button>
              {/each}
            </div>
          </div>

          {#if selectedRuntime}
            <div class="space-y-3">
              <div class="flex items-center gap-3">
                <p class="text-sm text-slate-300">Workload</p>
                <span class="text-xs text-slate-400">Uses query params on your single Function URL</span>
              </div>
              <div class="grid gap-3 md:grid-cols-2">
                {#each selectedRuntime.workloads as workload}
                  <label
                    class={`rounded-2xl border p-4 cursor-pointer transition-all duration-200 ${
                      selectedWorkloadId === workload.id
                        ? 'border-cyan-400/60 bg-cyan-400/10 shadow-neon'
                        : 'border-white/10 bg-white/5 hover:border-cyan-400/40'
                    }`}
                  >
                    <div class="flex items-start justify-between gap-3">
                      <div class="space-y-1">
                        <div class="flex items-center gap-2">
                          <input
                            type="radio"
                            name="workload"
                            value={workload.id}
                            checked={selectedWorkloadId === workload.id}
                            on:change={() => (selectedWorkloadId = workload.id)}
                            class="accent-cyan-400"
                          />
                          <p class="font-semibold">{workload.name}</p>
                        </div>
                        <p class="text-sm text-slate-300">{workload.description}</p>
                      </div>
                      <span class="text-[11px] px-2 py-1 rounded-full bg-white/5 text-slate-300 border border-white/10">
                        {selectedRuntime.name}
                      </span>
                    </div>
                  </label>
                {/each}
              </div>
            </div>
          {/if}

          <div class="space-y-2">
            <div class="flex items-center justify-between gap-3">
              <div class="flex items-center gap-3">
                <p class="text-sm text-slate-300">Configured URL</p>
                <span class="text-xs text-slate-400">One per runtime (stored locally)</span>
              </div>
              <button
                class="text-xs px-3 py-1 rounded-lg border border-white/10 bg-white/5 hover:border-cyan-400/50"
                on:click={openWizard}
              >
                Edit
              </button>
            </div>
            <div class="rounded-xl border border-white/10 bg-black/20 px-3 py-2 text-xs text-slate-200 break-all">
              {currentBaseUrl || 'Not set. Open setup to add your signed Function URL.'}
            </div>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            <button
              class="px-5 py-3 rounded-2xl bg-gradient-to-r from-cyan-400 to-blue-500 text-slate-900 font-semibold shadow-neon hover:scale-[1.01] transition"
              on:click={runFunction}
              disabled={isLoading || isAutoLoading}
            >
              {#if isLoading}
                <span class="flex items-center gap-2">
                  <span class="w-4 h-4 rounded-full border-2 border-white/50 border-t-white animate-spin"></span>
                  Calling Azure Function...
                </span>
              {:else}
                Call Function
              {/if}
            </button>

            <button
              class="px-5 py-3 rounded-2xl bg-gradient-to-r from-emerald-400 to-cyan-400 text-slate-900 font-semibold shadow-neon hover:scale-[1.01] transition"
              on:click={runAutomaticTests}
              disabled={isLoading || isAutoLoading}
            >
              {#if isAutoLoading}
                <span class="flex items-center gap-2">
                  <span class="w-4 h-4 rounded-full border-2 border-white/50 border-t-white animate-spin"></span>
                  Testing automatically...
                </span>
              {:else}
                Test automatically
              {/if}
            </button>

            <button
              class="px-4 py-3 rounded-2xl border border-white/10 bg-white/5 text-slate-200 hover:border-cyan-400/50 transition"
              on:click={clearHistory}
              disabled={isLoading || isAutoLoading}
            >
              Clear history
            </button>

            {#if message}
              <span class="text-sm text-emerald-300">{message}</span>
            {/if}
            {#if error}
              <span class="text-sm text-amber-300">{error}</span>
            {/if}
          </div>
        {/if}
      </div>

      <div class="glass-panel rounded-3xl p-6 md:p-7 space-y-5 border border-white/10">
        <div class="flex items-center justify-between gap-4">
          <div>
            <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Recent calls</p>
            <h2 class="text-lg font-semibold font-display">Timeline</h2>
          </div>
          <span class="text-xs text-slate-400">Last {recentRequests.length} requests</span>
        </div>

        <div class="space-y-2">
          <div class="flex items-center justify-between text-xs text-slate-400">
            <span>{minTs ? formatTime(minTs) : '--:--:--'}</span>
            <span>{maxTs ? formatTime(maxTs) : '--:--:--'}</span>
          </div>
          <div class="relative h-16 rounded-2xl border border-white/10 bg-white/5 overflow-hidden">
            {#if timelineRequests.length === 0}
              <div class="absolute inset-0 flex items-center justify-center text-sm text-slate-400">No calls yet</div>
            {/if}
            {#each timelineRequests as req, idx}
              <div
                class="absolute top-2 h-10 w-1.5 rounded-full shadow-lg transition-all"
                style={`left:${positionFor(req.timestamp)}%; background: linear-gradient(180deg, rgba(39,197,255,0.9), rgba(124,58,237,0.8)); transform: translateX(-50%); opacity:${0.35 + (idx / timelineRequests.length) * 0.65};`}
                title={`${req.runtimeName} | ${req.workloadName} | ${formatDuration(req.durationMs)}`}
              ></div>
            {/each}
          </div>
        </div>

        <div class="space-y-2">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Duration trend</p>
              <p class="text-sm text-slate-300">Y: ms • X: run count per runtime</p>
            </div>
            <div class="flex flex-wrap gap-2 text-xs">
              {#each seriesData.series as s}
                <span class="flex items-center gap-1 px-2 py-1 rounded-full border border-white/10 bg-white/5" style={`color:${s.color}; border-color:${s.color}33`}>
                  <span class="w-2.5 h-2.5 rounded-full" style={`background:${s.color}`}></span>
                  {s.runtimeName}
                </span>
              {/each}
              {#if seriesData.series.length === 0}
                <span class="text-xs text-slate-400">No data yet</span>
              {/if}
            </div>
          </div>
          <div class="rounded-2xl border border-white/10 bg-white/5 p-3 relative">
            {#if seriesData.series.length === 0}
              <div class="h-40 flex items-center justify-center text-sm text-slate-400">Run a request to see the graph</div>
            {:else}
              <svg
                viewBox={`0 0 ${seriesData.width} ${seriesData.height}`}
                class="w-full h-48"
                on:mouseleave={() => (hoveredPoint = null)}
                role="presentation"
                aria-hidden="true"
              >
                {#each seriesData.series as s}
                  <polyline
                    fill="none"
                    stroke={s.color}
                    stroke-width="2.5"
                    stroke-linecap="round"
                    points={s.path}
                  />
                  {#each s.points as p}
                    <circle
                      cx={p.x}
                      cy={p.y}
                      r="3"
                      fill={s.color}
                      role="presentation"
                      aria-hidden="true"
                      on:mouseenter={() =>
                        (hoveredPoint = {
                          runtimeName: p.runtimeName,
                          workloadName: p.workloadName,
                          runIndex: p.runIndex,
                          duration: p.duration,
                          x: p.x,
                          y: p.y,
                        })}
                      on:mouseleave={() => (hoveredPoint = null)}
                    />
                  {/each}
                {/each}
              </svg>

              {#if hoveredPoint}
                <div
                  class="absolute pointer-events-none"
                  style={`left:${(hoveredPoint.x / seriesData.width) * 100}%; top:${(hoveredPoint.y / seriesData.height) * 100}%; transform: translate(-50%, -120%);`}
                >
                  <div class="rounded-xl border border-white/20 bg-black/80 text-[11px] px-3 py-2 text-slate-100 shadow-lg backdrop-blur-sm">
                    <div class="font-semibold">{hoveredPoint.runtimeName}</div>
                    <div class="text-slate-300">{hoveredPoint.workloadName} • Run #{hoveredPoint.runIndex}</div>
                    <div class="text-cyan-200">{formatDuration(hoveredPoint.duration)}</div>
                  </div>
                </div>
              {/if}
            {/if}
          </div>
        </div>

        {#if recentRequests[0]}
          <div class="rounded-2xl border border-cyan-400/30 bg-cyan-400/10 p-4 shadow-neon">
            <p class="text-xs text-cyan-100 uppercase tracking-[0.2em]">Latest run</p>
            <div class="flex items-center justify-between gap-3">
              <div>
                <p class="text-sm text-cyan-50">{recentRequests[0].runtimeName} | {recentRequests[0].workloadName}</p>
                <p class="text-xs text-slate-200/80">{formatTime(recentRequests[0].timestamp)}</p>
              </div>
              <div class="text-right">
                <p class="text-lg font-semibold text-slate-900 px-3 py-1 rounded-xl bg-white/80 inline-block">
                  {formatDuration(recentRequests[0].durationMs)}
                </p>
                <p class="text-[11px] text-cyan-50 mt-1">Status {recentRequests[0].status}</p>
              </div>
            </div>
          </div>
        {/if}
      </div>
    </section>

    <section class="glass-panel rounded-3xl p-6 md:p-7 space-y-4">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Request log</p>
          <h2 class="text-xl font-semibold font-display">Recent requests</h2>
        </div>
        <span class="text-xs text-slate-400">Newest first</span>
      </div>

      {#if recentRequests.length === 0}
        <div class="rounded-2xl border border-dashed border-white/10 bg-white/5 p-5 text-sm text-slate-300">
          Run a request to see latency and status here.
        </div>
      {:else}
        <div class="grid gap-3">
          {#each recentRequests as req}
            <div class="rounded-2xl border border-white/10 bg-white/5 p-4 md:p-5 flex flex-col gap-3">
              <div class="flex flex-wrap items-center justify-between gap-3">
                <div class="flex items-center gap-3">
                  <span
                    class={`h-10 w-10 rounded-xl bg-gradient-to-br ${runtimeOptions.find((r) => r.id === req.runtimeId)?.accent ?? 'from-cyan-400 to-blue-500'} flex items-center justify-center text-sm font-semibold text-slate-900`}
                  >
                    {req.runtimeName[0]}
                  </span>
                  <div>
                    <p class="font-semibold">{req.runtimeName}</p>
                    <p class="text-sm text-slate-300">{req.workloadName}</p>
                  </div>
                </div>
                <div class="flex items-center gap-3">
                  <div class="text-right">
                    <p class="text-lg font-semibold text-slate-100">{formatDuration(req.durationMs)}</p>
                    <p class="text-xs text-slate-400">{formatTime(req.timestamp)}</p>
                  </div>
                  <span
                    class={`px-3 py-1 rounded-full text-xs border ${
                      req.ok ? 'bg-emerald-500/15 border-emerald-400/40 text-emerald-200' : 'bg-amber-500/15 border-amber-400/40 text-amber-200'
                    }`}
                  >
                    {req.ok ? 'OK' : 'Issue'} | {req.status}
                  </span>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex-1 h-2 rounded-full bg-white/5">
                  <div
                    class="h-2 rounded-full bg-gradient-to-r from-cyan-400 to-blue-500 transition-all"
                    style={`width: ${relativeDurationWidth(req.durationMs)}%; max-width: 100%;`}
                  ></div>
                </div>
                <code class="text-[11px] text-slate-300 font-mono bg-black/30 px-3 py-1 rounded-lg border border-white/5 break-all">
                  {req.url}
                </code>
              </div>

              {#if req.bodySnippet}
                <p class="text-xs text-slate-400 max-h-12 overflow-hidden">Response: {req.bodySnippet}</p>
              {/if}
            </div>
          {/each}
        </div>
      {/if}
    </section>
  </div>

  {#if showConfig}
    <div class="fixed inset-0 bg-black/70 backdrop-blur-sm z-[200] flex items-center justify-center px-4">
      <div class="max-h-[90vh] overflow-y-auto w-full max-w-4xl glass-panel rounded-3xl p-6 md:p-7 border border-cyan-400/40 space-y-6">
        <div class="flex items-center justify-between gap-3">
          <div>
            <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Setup wizard</p>
            <h3 class="text-xl font-semibold">Paste one signed Function URL per runtime</h3>
            <p class="text-sm text-slate-300">If left empty, that runtime will be hidden on the main screen.</p>
          </div>
          <button
            class="px-3 py-2 rounded-xl border border-white/10 bg-white/5 text-slate-200 hover:border-cyan-400/50"
            on:click={() => (showConfig = false)}
          >
            Close
          </button>
        </div>

        <div class="grid gap-3">
          {#each runtimeOptions as runtime}
            <div class="rounded-2xl border border-white/10 bg-white/5 p-4 space-y-2">
              <div class="flex items-center justify-between gap-3">
                <p class="text-sm font-semibold">{runtime.name}</p>
                {#if !(wizardUrls[runtime.id] ?? '').trim()}
                  <span class="text-[11px] text-amber-200">Not set</span>
                {:else}
                  <span class="text-[11px] text-emerald-200">Configured</span>
                {/if}
              </div>
              <input
                class="w-full rounded-xl border border-white/10 bg-black/20 px-3 py-2 text-xs text-slate-100 focus:border-cyan-400/70 focus:outline-none focus:ring-2 focus:ring-cyan-400/30"
                placeholder={runtime.placeholder}
                value={wizardUrls[runtime.id]}
                on:input={(e) => updateWizardUrl(runtime.id, e.currentTarget.value)}
              />
            </div>
          {/each}
        </div>

        {#if wizardError}
          <div class="text-sm text-amber-200">{wizardError}</div>
        {/if}

        <div class="flex items-center gap-3 justify-end">
          <button
            class="px-4 py-3 rounded-2xl border border-white/10 bg-white/5 text-slate-200 hover:border-cyan-400/50 transition"
            on:click={() => (showConfig = false)}
          >
            Cancel
          </button>
          <button
            class="px-5 py-3 rounded-2xl bg-gradient-to-r from-cyan-400 to-blue-500 text-slate-900 font-semibold shadow-neon hover:scale-[1.01] transition"
            on:click={saveWizard}
          >
            Save & continue
          </button>
        </div>
      </div>
    </div>
  {/if}
</main>
