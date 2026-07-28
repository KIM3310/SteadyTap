# Ad-Supported Resource and Aggregate Data Architecture

Repository: `SteadyTap`

## Public Resource Model

Free habit-loop worksheet for accessibility-minded mobile routine design.

- Audience: solo builders and wellness app prototypers
- Central resource: https://kim3310-doeon-kim-portfolio.pages.dev/resources/SteadyTap/
- Live system: https://steadytap.pages.dev
- Advertising boundary: ads allowed only on public habit-design articles and resource pages; personal routine tracking, reminders, and result screens are ad-free
- Current ad state: code-ready on the central resource; serving depends on Google AdSense site approval and consent policy.

## Readiness Utility

The central resource turns the repository architecture into a practical review checklist:

- **Architecture Summary:** Repository-local proof surface for edge, mobile, and local-first runtime systems, backed by Python service or lab runtime, Terraform infrastructure modules, Container build surface.
- **Runtime And Data Flow:** Primary domain: edge, mobile, and local-first runtime systems.
- **Cloud Or Local Deployment Boundary:** Operating model: optional sync backends, signed release artifacts, edge observability, and constrained compute envelopes
- **Deployment patterns:** Infrastructure-as-code entrypoint with explicit variables, outputs, and provider boundaries Containerized runtime path suitable for repeatable local, staging, or managed service deployment Edge-first deployment model with server-side AI adapters and public-safe secrets handling...
- **Control boundaries:** identity boundary and least-privilege service access environment separation for local, staging, and managed runtime paths secret storage outside source and deterministic fallback for missing credentials observability hooks for logs, metrics, traces, and audit events rollback path...

The checklist state remains in the visitor's browser and is not transmitted.

## Aggregate Data Boundary

- Data asset: anonymous aggregate habit-design resource demand and CTA counts
- Sensitivity class: consumer-guarded
- Allowed events: `resource_view`, `resource_cta_click`, `architecture_doc_open`, `privacy_support_open`
- Prohibited fields: `raw_input`, `url`, `referrer`, `title`, `user_id`, `session_id`, `ip_address`, `medical_detail`, `precise_location`, `payment_detail`
- Consent defaults to off.
- DNT and Global Privacy Control fail closed.
- Events are reduced to repository, allowlisted event, public surface, and consent-policy version.
- Personal, sensitive, raw, event-level, or re-identifiable data is never offered for sale.

## Storage Path

```text
Public resource
  -> consent and privacy-signal gate
  -> Cloudflare Pages event API
  -> rate-limited daily aggregate counter
  -> public benchmark response
  -> Firebase public aggregate data mart
```

Cloudflare D1 holds operational counters. Firestore project `kim3310-free-tools` is the deny-by-default public aggregate data mart. Private inquiries remain isolated from telemetry.
