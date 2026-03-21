# Employer Compensation Signal Registry

A longitudinal, employer-anchored compensation signal dataset built from public job postings—not self-reported surveys. The registry targets structured ATS APIs (Greenhouse, Lever, Ashby) for the bulk of collection, with browser-based fallbacks reserved for Workday and unknown ATS surfaces; normalization uses an LLM only where deterministic parsing is insufficient.

**References**

- [docs/PRODUCT_SPEC_V3.md](docs/PRODUCT_SPEC_V3.md) — full product specification
- [.cursor/rules/compensation-registry.mdc](.cursor/rules/compensation-registry.mdc) — Cursor project rules (taxonomy, collection, schema, analytics)
- [schema/schema.sql](schema/schema.sql) — PostgreSQL DDL for `companies`, `snapshots`, and `postings`
