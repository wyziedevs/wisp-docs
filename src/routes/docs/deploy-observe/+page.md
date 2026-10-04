---
title: Logs, Metrics and Traces
description: Watch a running Wisp app with JSON request logs, Prometheus metrics and OpenTelemetry traces, and learn how to turn each one on and read the output.
group: Deploy and Run
order: 64
---

All off until set. They work in the binary, Docker and Lambda, with no app code.

<div class="table-wrap">

| Env var | What it does |
|---|---|
| `WISP_LOG=json` | a JSON line per request on stdout (`off` default) |
| `METRICS_KEY` | serves `/_wisp/metrics` (Prometheus text) to `Authorization: Bearer <METRICS_KEY>` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | sends OTLP/HTTP JSON traces to `<endpoint>/v1/traces` (e.g. `http://localhost:4318`) |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | the traces URL, used as is |
| `OTEL_SERVICE_NAME` | service name on spans |
| `OTEL_EXPORTER_OTLP_HEADERS` | `api-key=…,x=…` |
| `OTEL_BSP_SCHEDULE_DELAY` | batch delay in ms (5000) |

</div>

## Logs

```json
{"time","method","route":"/blog/[slug]","path":"/blog/hello","status","ms","bytes","id","ip"}
```

- `route` is the route folder (null if none); `path` omits the query.
- `ip` is `cx.client_ip()` (see `WISP_CLIENT_IP_HEADER`).
- `id` is the client's `x-request-id`, or made, and is echoed.

## Metrics

Wrong or missing key: 401. `METRICS_KEY` unset: 404. Prometheus scrape config: `metrics_path: /_wisp/metrics`, `authorization: { credentials: <key> }`.

<div class="table-wrap">

| Metric | Notes |
|---|---|
| `wisp_requests_total{route, status}` | status class like `2xx`; `route=""` if none matched |
| `wisp_request_duration_seconds{route}` | histogram, 1 ms to 10 s |
| `wisp_requests_in_flight` | gauge |
| `wisp_uptime_seconds` | gauge |
| `process_resident_memory_bytes` | Linux only |

</div>

## Traces

- A server span per request (`GET /blog/[slug]`).
- An incoming `traceparent` is continued, and the reply carries its own (`trace` in `WISP_LOG=json`).
- A down collector costs requests nothing.
- Plain HTTP only: use a Collector for TLS.

```rust
let _s = wisp::span("charge card"); // child span until dropped
let t = wisp::traceparent(); // Some("00-…-01"): header for a downstream call
```
