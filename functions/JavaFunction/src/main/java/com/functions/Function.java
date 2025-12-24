package com.functions;

import com.microsoft.azure.functions.*;
import com.microsoft.azure.functions.annotation.*;
import java.nio.file.*;
import java.time.*;
import java.util.*;

public class Function {
    @FunctionName("JavaFunction")
    public HttpResponseMessage run(
            @HttpTrigger(name = "req", methods = {HttpMethod.GET, HttpMethod.POST}, authLevel = AuthorizationLevel.FUNCTION)
            HttpRequestMessage<Optional<String>> request,
            final ExecutionContext context) {

        String workload = Optional.ofNullable(request.getQueryParameters().get("workload")).orElse("").toLowerCase();
        int iterations = parseInt(request.getQueryParameters().get("iterations"), 250000);
        int sizeKb = parseInt(request.getQueryParameters().get("sizeKb"), 128);
        int delayMs = parseInt(request.getQueryParameters().get("delayMs"), 0);

        long start = System.nanoTime();

        switch (workload) {
            case "cpu":
                cpuWorkload(iterations);
                break;
            case "io":
                ioWorkload(sizeKb);
                break;
            case "delay":
                if (delayMs > 0) {
                    try { Thread.sleep(delayMs); } catch (InterruptedException ignored) { }
                }
                break;
            default:
                break;
        }

        double durationMs = Math.round((System.nanoTime() - start) / 1_000_000.0 * 100.0) / 100.0;

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("message", "Java example function");
        body.put("runtime", "java");
        body.put("workload", workload.isEmpty() ? "none" : workload);
        body.put("iterations", iterations);
        body.put("sizeKb", sizeKb);
        body.put("delayMs", delayMs);
        body.put("durationMs", durationMs);
        body.put("timestamp", OffsetDateTime.now(ZoneOffset.UTC).toString());
        body.put("requestData", Map.of(
                "query", request.getQueryParameters(),
                "method", request.getHttpMethod().toString()
        ));

        return request
                .createResponseBuilder(HttpStatus.OK)
                .header("content-type", "application/json")
                .header("x-runtime", "java")
                .body(body)
                .build();
    }

    private static int parseInt(String value, int fallback) {
        try { return Integer.parseInt(value); } catch (Exception e) { return fallback; }
    }

    private static void cpuWorkload(int iterations) {
        double acc = 0;
        for (int i = 1; i <= iterations; i++) {
            acc += Math.sqrt(i) / Math.log(i + 1);
        }
        if (acc == 42) { System.out.println("unlikely"); }
    }

    private static void ioWorkload(int sizeKb) {
        try {
            byte[] bytes = new byte[sizeKb * 1024];
            new Random().nextBytes(bytes);
            Path tmp = Files.createTempFile("fn-", ".bin");
            Files.write(tmp, bytes);
            Files.readAllBytes(tmp);
            Files.deleteIfExists(tmp);
        } catch (Exception ignored) { }
    }
}
