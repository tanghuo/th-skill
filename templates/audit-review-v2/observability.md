# Observability Audit

```text
Audit whether important production failures can be detected, explained, and
debugged with existing logs, metrics, traces, and operational records.

Starting points to customize:
- Critical user workflows and incident scenarios: {{critical_workflow_paths}}
- Error-handling and external call boundaries: {{boundary_paths}}
- Metrics, tracing, and logging setup: {{observability_paths}}
- Jobs and asynchronous workflows: {{job_paths}}

Incident-walkthrough method:
- Pick a realistic failure scenario.
- Trace the operator's evidence trail from user symptom to root cause.
- Report missing or misleading signals only when they block diagnosis or alerting.

Check:
- External calls lack status, duration, dependency name, business key, or error
  classification.
- Async work loses correlation IDs, object IDs, attempt counts, or terminal
  failure summaries.
- Queue/stream/backpressure/overflow paths lack metrics or logs.
- Important state transitions lack before/after/state-reason visibility.
- Metrics exist but cannot be scraped, labeled safely, or tied to user impact.
- Logs contain too much noise but not the decisive state needed for debugging.
- Panic or crash logs lack stack, object key, or worker identity.

For each finding, include the incident scenario, missing evidence, why current
signals are insufficient, operational impact, and minimal repair direction.
```
