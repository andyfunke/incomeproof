# Employer Compensation Signal Registry: Complete Product Specification v3

## Product Definition and Thesis

You are building a time-series dataset of how specific employers price specific roles in specific markets, derived from what those employers publish publicly in job postings. This is meaningfully different from self-reported compensation databases like Levels.fyi. The core asymmetry is that self-reported databases reflect the population of people who chose to submit data, which skews heavily toward people who received strong offers, work at FAANG-tier companies, and are in software engineering. Your dataset reflects what employers actually put into the market, constrained by pay transparency law, public optics, and competitive dynamics.

The commercial positioning: you observe live employer compensation signals over time. You are not a job board. You are not a survey. You are a longitudinal observation system for what employers say they will pay.

The product's defensibility accumulates every day the system runs. Longitudinal snapshot history cannot be retroactively acquired by a competitor. That is the moat.

---

## What You Are Not Building

You are not building a general internet crawler. You are not dispatching an AI agent to browse every company website. You are not trying to capture every employer in the United States on day one. You are not competing with Indeed or LinkedIn for posting coverage. You are building a narrow, high-signal registry of target employers with structured collectors, and you are watching that registry systematically over time. Never mix candidate-reported compensation into the same tables as employer-posted ranges.

---

## Geographic Scope

Primary metros for v1: Seattle and Washington State broadly, Bay Area, SoCal (LA/San Diego), New York, Boston, Austin, Charlotte. Remote-first employers are included as their own segment regardless of headquarters location, because they frequently post salary ranges that are geographically meaningful.

---

## Role Family and Level Taxonomy

### Role Families

The system tracks nine role families. These are not borrowed from any third-party taxonomy; they reflect how employers actually structure job postings.

- **SWE** covers all software engineering roles: frontend, backend, fullstack, mobile, generalist.
- **Infra** covers infrastructure engineering, platform engineering, SRE, DevOps, cloud engineering, and systems engineering.
- **Data** covers data engineering, data science, machine learning engineering, AI engineering, and ML research engineering.
- **TPM** covers technical program management, engineering program management, and technical project management.
- **PM** covers product management and technical product management.
- **EM** covers engineering management at all levels. This family uses only the manager track (M1 through M4).
- **Recruiting** covers technical recruiting and engineering recruiting. Included because recruiter compensation correlates meaningfully with company hiring posture and budget and is increasingly salary-transparent.
- **IT/Network** covers IT support, help desk, network engineering, sysadmin, and systems administration.
- **Controls/Industrial** covers controls engineering, automation engineering, industrial systems engineering, commissioning engineering, and PLC technicians. This family uses a specialized level scheme described below.

### Individual Contributor Track: IC1 through IC6

These levels apply to SWE, Infra, Data, TPM, PM, Recruiting, and IT/Network.

- **IC1** is entry level. New graduate hires, first professional role. Maps to Google L3, Meta E3, Amazon L4/SDE I, Microsoft 59. Typical total compensation: $100k to $160k, lower end of that in non-Bay metros.
- **IC2** is mid-level. Solid contributor, works independently on defined problems. Maps to Google L4, Meta E4, Amazon L5/SDE II, Microsoft 61. Typical total compensation: $140k to $220k.
- **IC3** is Senior. Career-level position at most companies. This is where the largest population of experienced engineers sits and where the most job postings appear. Maps to Google L5, Meta E5, Amazon L6/SDE III, Microsoft 63 to 64. Typical total compensation: $180k to $300k at larger tech employers, lower in non-Bay and non-NY markets.
- **IC4** is Staff. Scope extends beyond a single team. Maps to Google L6, Meta E6, Amazon L7/Principal, Microsoft 65 to 66. Typical total compensation: $250k to $400k+.
- **IC5** is Principal. Org-level or major system-level scope. Maps to Google L7, Meta E7, Amazon L7+ Distinguished, Microsoft 67. Typical total compensation: $350k to $600k+.
- **IC6** is Distinguished or Fellow. Rare, highly company-specific. Maps to L8+ and equivalents.

### Manager Track: M1 through M4

Applies to EM family. Also used for senior-level managers in Recruiting and IT/Network when the posting is clearly a people-management role.

- **M1** is Engineering Manager or Tech Lead Manager. Front-line management of one to two teams. Compensation equivalent to IC3 to IC4 range at most companies.
- **M2** is Senior Engineering Manager or Group EM. Manages managers or multiple teams. Compensation equivalent to IC4 to IC5 range.
- **M3** is Director of Engineering. Owns a product area or functional domain.
- **M4** is VP of Engineering and above. Rarely observed in external job postings.

### Controls and Industrial Track: T1 through T2, E1 through E4, CM1 through CM2

This track is separate because the Controls/Industrial family has a different labor market structure than tech roles. Many of these roles exist outside the tech ATS ecosystem entirely, which affects collection strategy.

- **T1** is PLC Technician I or II. Hourly or salaried technician roles. Typical annualized compensation: $60k to $85k, with premium for night shift, remote industrial sites, or specialized certifications. Collection note: these roles frequently appear on Indeed and ZipRecruiter rather than Greenhouse or Lever.
- **T2** is Senior PLC Technician or Lead Technician. Top of the technician track.
- **E1** is Controls Engineer or Automation Engineer at the junior to mid level. Typical compensation: $80k to $110k nationally.
- **E2** is Senior Controls Engineer, Senior Automation Engineer, or Senior Industrial Systems Engineer. The career-level position in this family. Typical compensation: $100k to $135k nationally, with Seattle/PNW automation market running roughly $120k to $140k for senior roles.
- **E3** is Staff or Principal Controls/Automation Engineer. Architectural scope, often quasi-management.
- **E4** is Lead Engineer or Principal Industrial Engineer at the top of the IC track for this family.
- **CM1** is Commissioning Engineer. This is treated as a separate branch because commissioning is a project-based specialty with different comp norms (often higher total comp due to travel premium, per diem, and project bonuses). Typical compensation: $90k to $130k base plus significant per diem and travel compensation.
- **CM2** is Senior or Lead Commissioning Engineer.

### Salary Range Normalization

All compensation is stored and reported as annualized USD base salary only. For hourly postings (common in Controls/Industrial), multiply by 2,080 for the standard full-time equivalent. Bonus and equity language is captured as metadata only—never written into `salary_min_usd`, `salary_max_usd`, or `salary_midpoint_usd`. `salary_midpoint_usd` is always computed as `(salary_min_usd + salary_max_usd) / 2` (never user-supplied). `salary_spread_pct` is always computed as `(salary_max_usd - salary_min_usd) / salary_min_usd × 100`. Any posting where `salary_spread_pct` exceeds 60 must set `multi_level_range = true`; exclude these from single-level analysis by default and treat midpoints conservatively when included.

---

## Data Sources by Role Family

The key insight from the prior conversation is that different role families live in different data ecosystems. A single collection strategy does not serve all of them.

For SWE, Infra, Data, TPM, PM, and EM roles at tech companies, the primary collection surface is first-party company career pages via the structured ATS APIs described in the collection algorithm section below. These are the roles where Greenhouse, Lever, and Ashby coverage is densest, where pay transparency laws are generating real salary range data, and where longitudinal employer-posted data is most differentiated from Levels.fyi.

For Recruiting roles, first-party career pages work for tech-sector employers. BuiltIn by city is a useful supplementary board because it tends to carry salary data and is tech-sector focused.

For IT/Network roles, first-party career pages work for tech employers. BuiltIn and ZipRecruiter by metro provide broader market signal. Salary.com provides useful percentile anchors for these roles since they are more commoditized.

For Controls/Industrial roles, the collection strategy is fundamentally different. Most Controls and Automation employers do not use Greenhouse or Lever. They use Workday, iCIMS, or proprietary career pages, and they frequently post on Indeed, ZipRecruiter, and industry-specific boards. The structured ATS API approach covers a smaller fraction of this universe. For this family, a hybrid approach is required: ATS-native collection for tech-adjacent industrial companies that happen to use Greenhouse or Lever, supplemented by board-level collection from Indeed and ZipRecruiter using specific saved searches per metro and role combination. Salary.com and PayScale are also useful percentile reference sources for this family since they have better coverage of non-tech industries. Board-level rows for this family must always use `source_type: board` and must never be mixed with `source_type: company_career_page` when computing employer-specific trends.

---

## Collection Architecture: Computer Use vs HTTP

**Claude Computer Use (or similar GUI agents) should not be the primary collection layer.**

Computer is designed for tasks where a human would navigate a GUI, click through pages, fill forms, and read rendered content. The collection architecture as specified does not need it for the majority of target companies, because Greenhouse, Lever, and Ashby expose clean JSON APIs that an HTTP client can call with a single request. Using a browser agent for endpoints like `boards-api.greenhouse.io/v1/boards/{token}/jobs` adds agent latency, token cost, and fragility for work a simple HTTP client handles in milliseconds.

**Where Computer (or headless browser) earns its keep:** the narrow fallback tier—Workday and unknown ATS sites that require a rendered browser session to obtain job data. That tier should be a small fraction of total poll volume, not the backbone.

**Framing:** Python with `httpx` or `requests` for structured API tiers (Greenhouse, Lever, Ashby); Playwright or Puppeteer (headless browser) for Workday and unknown legacy ATS fallback; Claude API calls (not Computer Use) for LLM normalization after collection.

---

## Data Collection Algorithm: Verified Endpoint Architecture

### Layer 1: Greenhouse (Unauthenticated, Structured JSON, No Rate Limits)

Job Board data is publicly available, so authentication is not required for any GET endpoints.

There are no stated rate limits on the Job Board API.

Call: `GET https://boards-api.greenhouse.io/v1/boards/{board_token}/jobs?content=true`

Response fields include job title, `updated_at` timestamp, `requisition_id`, location, full content HTML, department hierarchy, and office structure with location metadata.

The `board_token` is the slug at `boards.greenhouse.io/{token}`, discoverable from the careers page and stable indefinitely.

Limitation: the Job Board API does not expose the time a job was first published, only when last updated. Assign your own `first_observed_at` from the first snapshot where an `external_id` appears.

### Layer 2: Lever (Unauthenticated, Structured JSON, Salary Fields Native)

Every Lever customer has a public API that allows job retrieval with no authentication required, at `GET https://api.lever.co/v0/postings/{clientname}`.

Each posting includes an optional salary object with currency, interval, minimum, and maximum values, plus an optional salary range description as both styled HTML and plain text. Always check the salary object before falling back to description parsing.

### Layer 3: Ashby (Unauthenticated, Structured JSON, Native Compensation Fields)

The endpoint is `GET https://api.ashbyhq.com/posting-api/job-board/{clientname}?includeCompensation=true`.

Response includes `compensationTierSummary`, `scrapeableCompensationSalarySummary`, and structured `compensationTiers` objects. Always include `includeCompensation=true`.

### Layer 4: Workday (Browser Rendering Required, Phase 2)

Workday does not have a public-facing API. Collection requires intercepting the XHR calls that Workday frontend pages make to their internal search endpoint. This is feasible via Playwright or Puppeteer, following the consistent `{company}.wd1.myworkdayjobs.com` URL schema. **Do not implement Workday collection in v1** (phase 2 only).

### Layer 5: Job Boards for Controls/Industrial and Broader Market Signal

For roles where ATS-native collection is insufficient, collect from Indeed and ZipRecruiter using saved searches scoped to metro and role. These are not longitudinal employer records in the same sense; they are market-level signals used to anchor and validate the employer-posted data. Store these separately in the data model and label them `source_type: board` rather than `source_type: company_career_page` so they are never mixed when computing employer-specific trends.

---

## Data Model

### Company Registry

```
company_id           UUID
canonical_name
canonical_domain
careers_url
ats_type             greenhouse | lever | ashby | workday | icims | indeed_only | unknown
ats_board_token
metro                primary metro or "remote-first"
industry             tech | fintech | healthcare | industrial | manufacturing | other
size_band            seed | series_a_c | growth | public | enterprise
polling_tier         1 | 2 | 3 | 99 (inactive)
last_successful_poll timestamp
salary_transparency  high | medium | low | unknown
role_family_tags     array
```

### Snapshot

```
snapshot_id
company_id
observed_at
source_url
raw_payload          compressed JSON blob
job_count
```

### Normalized Posting

```
posting_id
snapshot_id
company_id
external_id          platform's own job ID (stable key for versioning)
title_raw
title_normalized
level_code           IC1–IC6 | M1–M4 | T1–T2 | E1–E4 | CM1–CM2
role_family          swe | infra | data | tpm | pm | em | recruiting | it_network | controls_industrial
location_raw
metro_normalized
is_remote
salary_min_raw
salary_min_usd       integer, annualized base
salary_max_raw
salary_max_usd
salary_midpoint_usd  computed: (min + max) / 2; never user-supplied
salary_spread_pct    computed: (max - min) / min × 100
multi_level_range    true when salary_spread_pct > 60; exclude from single-level analysis by default
salary_source        structured_api | parsed_description | absent
comp_type_tag        base_only | base_ote_mentioned | base_bonus_equity_mentioned
transparency_quality exact_range | vague | absent
description_hash     SHA-256 for change detection
first_observed_at
last_observed_at
status               active | presumed_closed
version_number       integer, increments when salary range changes
source_type          company_career_page | board (default: company_career_page)
```

The `version_number` field is critical for longitudinal analysis. When a poll detects that `salary_min_usd` or `salary_max_usd` has changed for an existing `(company_id, external_id)` pair, **INSERT** a new posting row with `version_number` incremented. **Do not** update the prior row’s salary fields—never overwrite historical salary data.

The `salary_spread_pct` and `multi_level_range` fields address a known bias in pay transparency law posting: companies increasingly post very wide ranges that cover multiple levels. Treat wide-range midpoints conservatively or exclude them from single-level analysis when `multi_level_range` is true.

---

## LLM Normalization Layer

Three tasks only. Everything else is deterministic.

1. **Title normalization** returns `{normalized_title, role_family, level_code}` as JSON only (no prose). Input: raw title, known company-level naming conventions for this `company_id`, full taxonomy reference. Cache key: `(company_id, title_raw)`.
2. **Salary extraction from description text** handles the case where structured salary fields are absent (common for Workday and legacy ATS). Output JSON includes `salary_min_usd`, `salary_max_usd`, and `salary_source: "parsed_description"`. Cache key: `description_hash`—never re-run for an unchanged description.
3. **Metro normalization** resolves ambiguous location strings to a standard metro key. Cache aggressively; most patterns recur constantly.

What LLM does not do: fetching, scheduling, routing, or any control flow decision.

---

## Polling Scheduler

Priority queue ordered by `next_poll_due_at`. Workers are stateless.

- Tier 1: every 24 hours  
- Tier 2: every 3–7 days  
- Tier 3: every 2–4 weeks  
- Inactive (tier 99): monthly  

HTTP 429 or consecutive 5xx responses trigger exponential backoff. Three consecutive failures flag the company for human review and suspend further polling.

At 10,000 companies with average 4-day cadence: approximately 2,500 polls per day, ~1.75 per minute. No distributed queue infrastructure required at v1 scale. A single scheduler process and 5–10 workers handles this comfortably.

---

## Analytical Integrity Rules

- When querying compensation trends, filter `source_type = 'company_career_page'` unless explicitly doing market-wide analysis.
- When querying single-level compensation, filter `multi_level_range = false` or explicitly document that wide ranges are included.
- When comparing across time, use `first_observed_at` on each `version_number` row to timestamp the salary range—not the snapshot’s `observed_at`.
- Never average salary across different `comp_type_tag` values without flagging it; `base_only` and `base_ote_mentioned` are not comparable.
- Controls/Industrial comp benchmarks are national unless a metro is specified; Seattle/PNW runs roughly $15k–$20k above national median for E2.

---

## What You Can Say About Your Data That Levels Cannot

Your data is employer-anchored, not candidate-anchored. It captures what companies advertise they will pay for a profile right now, constrained by pay transparency law and public competitive dynamics, rather than what candidates with strong offers chose to self-report.

Your data is a time series. You can show compensation trends by company, city, and role: "Bay Area Senior SWE posted midpoints compressed between 2024 and 2026 while NYC EM posted ranges widened." That sentence is not possible from a self-reported database without extraordinary data quality controls that Levels does not have.

Your data covers controls, industrial, and commissioning roles alongside software and tech roles under one normalization scheme. No major existing database does this.

Your data includes transparency analytics as a product layer: which employers consistently post narrow, realistic bands versus wide ranges that span multiple levels, and how that shifts as pay transparency laws expand into new states.

The honest statement of your limitations is also the right one to lead with to sophisticated users: you capture what employers say they will pay, not what candidates actually signed. You cannot claim that posted ranges reflect final negotiated compensation, or full coverage where employers omit ranges (`transparency_quality: absent`).

If candidate-reported closed offer data is ever added, the delta between posted ranges and closed offers for the same roles at the same companies over time is itself a valuable and separately publishable product—keep the schema clean enough to support that join without mixing sources in the same analytical tables.
