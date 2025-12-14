# Java Function note

This sample uses the same workload parameters as the other runtimes:

- `workload=cpu|io|delay`
- `iterations` (for cpu)
- `sizeKb` (for io)
- `delayMs` (for delay)

The Java worker generates `function.json` at build time. Build with the standard Maven Azure Functions template to produce the deployable artifact; place this class under your project package and ensure the function name is `JavaFunction` to match your routing.
