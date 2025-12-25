using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;

namespace DotnetFunction;

public class DotnetFunction
{
    [Function("DotnetFunction")]
    public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData req)
    {
        var query = ParseQuery(req.Url);
        var workload = GetValue(query, "workload").ToLowerInvariant();
        var iterations = ParseInt(GetValue(query, "iterations"), 250000);
        var sizeKb = ParseInt(GetValue(query, "sizeKb"), 128);
        var delayMs = ParseInt(GetValue(query, "delayMs"), 0);

        var sw = System.Diagnostics.Stopwatch.StartNew();

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

        var payload = new
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
                query,
                method = req.Method
            }
        };

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("content-type", "application/json");
        response.Headers.Add("x-runtime", "dotnet");
        await response.WriteStringAsync(JsonSerializer.Serialize(payload));
        return response;
    }

    private static string GetValue(IReadOnlyDictionary<string, string> query, string key)
    {
        return query.TryGetValue(key, out var value) ? value : string.Empty;
    }

    private static int ParseInt(string input, int fallback)
    {
        return int.TryParse(input, out var val) ? val : fallback;
    }

    private static void CpuWorkload(int iterations)
    {
        double acc = 0;
        for (int i = 1; i <= iterations; i++)
        {
            acc += Math.Sqrt(i) / Math.Log(i + 1);
        }
        GC.KeepAlive(acc);
    }

    private static void IoWorkload(int sizeKb)
    {
        var bytes = new byte[sizeKb * 1024];
        new Random().NextBytes(bytes);

        var tmp = Path.GetTempFileName();
        File.WriteAllBytes(tmp, bytes);
        _ = File.ReadAllBytes(tmp).Length;
        try { File.Delete(tmp); } catch { }
    }

    private static Dictionary<string, string> ParseQuery(Uri url)
    {
        var query = url.Query;
        if (string.IsNullOrWhiteSpace(query))
        {
            return new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        }

        if (query.StartsWith("?"))
        {
            query = query[1..];
        }

        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var part in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var kvp = part.Split('=', 2);
            var key = Uri.UnescapeDataString(kvp[0]);
            var value = kvp.Length > 1 ? Uri.UnescapeDataString(kvp[1]) : string.Empty;
            if (!string.IsNullOrWhiteSpace(key))
            {
                result[key] = value;
            }
        }

        return result;
    }
}
