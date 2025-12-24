param($Request, $TriggerMetadata)

# Simple PowerShell workload sampler for Azure Functions.
# Supports query params:
#   workload=cpu|io|delay  (defaults to none)
#   iterations=<int>       (for cpu)
#   sizeKb=<int>           (for io)
#   delayMs=<int>          (for delay)

$workload = $Request.Query.workload
$iterations = [int]($Request.Query.iterations ?? 250000)
$sizeKb = [int]($Request.Query.sizeKb ?? 128)
$delayMs = [int]($Request.Query.delayMs ?? 0)

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

function Invoke-CpuWorkload {
    param([int]$Iterations)

    $acc = 0.0
    for ($i = 1; $i -le $Iterations; $i++) {
        # Basic floating point math to keep the CPU busy.
        $acc += [math]::Sqrt($i) / [math]::Log($i + 1)
    }
    return $acc
}

function Invoke-IoWorkload {
    param([int]$SizeKb)

    $bytes = New-Object byte[] ($SizeKb * 1024)
    [System.Random]::new().NextBytes($bytes)

    $tempPath = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllBytes($tempPath, $bytes)
    $readBack = [System.IO.File]::ReadAllBytes($tempPath).Length
    Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue

    return $readBack
}

switch ($workload) {
    'cpu'   { Invoke-CpuWorkload -Iterations $iterations | Out-Null }
    'io'    { Invoke-IoWorkload -SizeKb $sizeKb | Out-Null }
    'delay' { if ($delayMs -gt 0) { Start-Sleep -Milliseconds $delayMs } }
    default { }
}

$stopwatch.Stop()

$body = [pscustomobject]@{
    message     = 'PowerShell example function'
    runtime     = 'powershell'
    workload    = $workload ?? 'none'
    iterations  = $iterations
    sizeKb      = $sizeKb
    delayMs     = $delayMs
    durationMs  = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 2)
    timestamp   = (Get-Date).ToString('o')
    requestData = @{
        query = $Request.Query
        method = $Request.Method
    }
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Headers    = @{
        'content-type' = 'application/json'
        'x-runtime'    = 'powershell'
    }
    Body       = ($body | ConvertTo-Json -Depth 5)
})
