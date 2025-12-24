const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');

module.exports = async function (context, req) {
  const workload = (req.query.workload || '').toLowerCase();
  const iterations = parseInt(req.query.iterations || '250000', 10);
  const sizeKb = parseInt(req.query.sizeKb || '128', 10);
  const delayMs = parseInt(req.query.delayMs || '0', 10);

  const started = Date.now();
  const startedPerf = process.hrtime.bigint();

  const cpuWorkload = (count) => {
    let acc = 0;
    for (let i = 1; i <= count; i++) {
      acc += Math.sqrt(i) / Math.log(i + 1);
    }
    return acc;
  };

  const ioWorkload = (kb) => {
    const buffer = crypto.randomBytes(kb * 1024);
    const tmp = path.join(os.tmpdir(), `fn-${process.pid}-${Date.now()}.bin`);
    fs.writeFileSync(tmp, buffer);
    const len = fs.readFileSync(tmp).length;
    fs.unlinkSync(tmp);
    return len;
  };

  if (workload === 'cpu') {
    cpuWorkload(iterations);
  } else if (workload === 'io') {
    ioWorkload(sizeKb);
  } else if (workload === 'delay' && delayMs > 0) {
    await new Promise((resolve) => setTimeout(resolve, delayMs));
  }

  const durationMs = Number((Number(process.hrtime.bigint() - startedPerf) / 1e6).toFixed(2));

  context.res = {
    status: 200,
    headers: {
      'content-type': 'application/json',
      'x-runtime': 'node'
    },
    body: {
      message: 'Node.js example function',
      runtime: 'node',
      workload: workload || 'none',
      iterations,
      sizeKb,
      delayMs,
      durationMs,
      timestamp: new Date(started).toISOString(),
      requestData: {
        query: req.query,
        method: req.method
      }
    }
  };
};
