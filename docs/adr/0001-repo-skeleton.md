# ADR 0001: Repository Skeleton (INF-01)
Date: 2025-09-15
Status: Accepted

## Decision
- Establish a minimal, consistent repository structure to unblock INF-02, INF-05, INF-06 and DATA-*.

## Options
- Flat layout per layer vs. monorepo-style packages; include only directories needed by MVP; keep code-free placeholders.

## Consequences
- Fast onboarding, clear ownership per layer, easy CI wiring; low risk of secrets in VCS.
