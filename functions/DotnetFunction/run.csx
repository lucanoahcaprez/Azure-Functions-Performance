#r "System.Runtime"
#r "System.Net.Http"
using System.Net;
using System.Net.Http;
using System.Diagnostics;

public static async Task Run(HttpRequest req, HttpResponse res, ILogger log)
{
    string workload = (req.Query["workload"].FirstOrDefault() ?? "").ToLowerInvariant();
    int iterations = ParseInt(req.Query["iterations"], 250000);
    int sizeKb = ParseInt(req.Query["sizeKb"], 128);
    int delayMs = ParseInt(req.Query["delayMs"], 0);

    var sw = Stopwatch.StartNew();

    if (workload == "cpu")
    {
        CpuWorkload(iterations);
    }
    else if (workload == "io")
    {
        IoWorkload(sizeKb);
    }
    else if (workload == "delay" && delayMs > 0)
    {
        await Task.Delay(delayMs);
    }

    sw.Stop();

    var body = new
    {
        message = "C# example function",
        runtime = "dotnet",
        workload = string.IsNullOrEmpty(workload) ? "none" : workload,
        iterations,
        sizeKb,
        delayMs,
        durationMs = Math.Round(sw.Elapsed.TotalMilliseconds, 2),
        timestamp = DateTime.UtcNow.ToString("o"),
        requestData = new
        {
            query = req.Query.ToDictionary(kvp => kvp.Key, kvp => kvp.Value.ToString()),
            method = req.Method
        }
    };

    res.StatusCode = (int)HttpStatusCode.OK;
    res.Headers.Add("content-type", "application/json");
    res.Headers.Add("x-runtime", "dotnet");
    await res.WriteAsync(System.Text.Json.JsonSerializer.Serialize(body));
}

static int ParseInt(string input, int fallback)
{
    return int.TryParse(input, out var val) ? val : fallback;
}

static void CpuWorkload(int iterations)
{
    double acc = 0;
    for (int i = 1; i <= iterations; i++)
    {
        acc += Math.Sqrt(i) / Math.Log(i + 1);
    }
    GC.KeepAlive(acc);
}

static void IoWorkload(int sizeKb)
{
    var bytes = new byte[sizeKb * 1024];
    new Random().NextBytes(bytes);

    var tmp = Path.GetTempFileName();
    File.WriteAllBytes(tmp, bytes);
    var read = File.ReadAllBytes(tmp).Length;
    try { File.Delete(tmp); } catch { }
}
