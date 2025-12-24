import json
import logging
import math
import os
import tempfile
import time
from datetime import datetime
import azure.functions as func

def _cpu_workload(iterations: int) -> float:
    acc = 0.0
    for i in range(1, iterations + 1):
        acc += math.sqrt(i) / math.log(i + 1)
    return acc

def _io_workload(size_kb: int) -> int:
    data = os.urandom(size_kb * 1024)
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp.write(data)
        path = tmp.name
    with open(path, "rb") as f:
        length = len(f.read())
    try:
        os.remove(path)
    except OSError:
        logging.warning("Temp file cleanup failed")
    return length

def main(req: func.HttpRequest) -> func.HttpResponse:
    workload = (req.params.get("workload") or "").lower()
    iterations = int(req.params.get("iterations") or 250000)
    size_kb = int(req.params.get("sizeKb") or 128)
    delay_ms = int(req.params.get("delayMs") or 0)

    start = time.perf_counter()

    if workload == "cpu":
        _cpu_workload(iterations)
    elif workload == "io":
        _io_workload(size_kb)
    elif workload == "delay" and delay_ms > 0:
        time.sleep(delay_ms / 1000.0)

    duration_ms = round((time.perf_counter() - start) * 1000, 2)

    body = {
        "message": "Python example function",
        "runtime": "python",
        "workload": workload or "none",
        "iterations": iterations,
        "sizeKb": size_kb,
        "delayMs": delay_ms,
        "durationMs": duration_ms,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "requestData": {
            "query": dict(req.params),
            "method": req.method,
        },
    }

    return func.HttpResponse(
        json.dumps(body),
        mimetype="application/json",
        status_code=200,
        headers={"x-runtime": "python"},
    )
