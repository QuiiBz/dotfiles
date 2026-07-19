---
name: dd-apm
description: APM - install, onboard, instrument, enable, set up, configure, traces, services, dependencies, performance analysis. Use for any request involving Datadog APM setup, instrumentation (ddtrace, agent install), or analysis.
alwaysApply: true
metadata:
  version: "1.1.0"
  author: datadog-labs
  repository: https://github.com/datadog-labs/agent-skills
  tags: datadog,apm,tracing,performance,distributed-tracing,dd-apm,install,onboarding,instrumentation,agent
  globs: "**/ddtrace*,**/datadog*.yaml,**/*trace*"
---

# Datadog APM

Distributed tracing, service maps, and performance analysis.

## Routing — Read This First

Match the user's request to one of the entries below. Each entry has the same shape: **triggers** → which sub-skill to load → the anti-pattern to avoid. If a request seems to fit more than one entry, see "Overlap disambiguation". If nothing matches, see "None of the above" at the end.

---

### None of the above

If the request doesn't match any entry above, continue reading the trace-search, service analysis, and metrics content below. If even that doesn't fit, **ask the user to clarify** — do not invent a workflow.

---

## Requirements

Datadog Labs Pup should be installed. See [Setup Pup](https://github.com/datadog-labs/agent-skills/tree/main?tab=readme-ov-file#setup-pup) if not.

## Command Execution Order (Token-Efficient)

For scoped commands, use this order:

1. Check context first (prior outputs, conversation, saved values).
2. If a required value is missing, run a discovery command first.
3. If still ambiguous, ask the user to confirm.
4. Then run the target command.
5. Avoid speculative commands likely to fail.

## Quick Start

```bash
pup auth login
# Confirm env tag with the user first (do not assume production/prod/prd).
pup apm services list --env <env> --from 1h --to now
pup traces search --query "service:api-gateway" --from 1h
```

## Services

### List Services

```bash
pup apm services list --env <env> --from 1h --to now
pup apm services stats --env <env> --from 1h --to now
```

### Service Stats

```bash
pup apm services stats --env <env> --from 1h --to now
```

### Service Map

```bash
# View dependencies
pup apm flow-map --query "service:api-gateway&from=$(($(date +%s)-3600))000&to=$(date +%s)000" --env <env> --limit 10
```

## Traces

### Search Traces

```bash
# By service
pup traces search --query "service:api-gateway" --from 1h

# Errors only
pup traces search --query "service:api-gateway status:error" --from 1h

# Slow traces (>1s)
pup traces search --query "service:api-gateway @duration:>1000ms" --from 1h

# With specific tag
pup traces search --query "service:api-gateway @http.url:/api/users" --from 1h
```

### Trace Detail

```bash
# No direct get command for a single trace ID.
# Use traces search with a narrow query and time window.
pup traces search --query "trace_id:<trace_id>" --from 1h
```

## Key Metrics

| Metric | What It Measures |
|--------|------------------|
| `trace.http.request.hits` | Request count |
| `trace.http.request.duration` | Latency |
| `trace.http.request.errors` | Error count |
| `trace.http.request.apdex` | User satisfaction |

## Service Level Objectives

Link APM to SLOs:

```bash
pup slos create --file slo.json
```

## Common Queries

| Goal | Query |
|------|-------|
| Slowest endpoints | `avg:trace.http.request.duration{*} by {resource_name}` |
| Error rate | `sum:trace.http.request.errors{*} / sum:trace.http.request.hits{*}` |
| Throughput | `sum:trace.http.request.hits{*}.as_rate()` |

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No traces | Check ddtrace installed, DD_TRACE_ENABLED=true |
| Missing service | Verify DD_SERVICE env var |
| Traces not linked | Check trace headers propagated |
| High cardinality | Don't tag with user_id/request_id |

## References/Docs

- [APM Setup](https://docs.datadoghq.com/tracing/)
- [Trace Search](https://docs.datadoghq.com/tracing/trace_explorer/)
