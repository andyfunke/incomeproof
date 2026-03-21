-- Employer Compensation Signal Registry — PostgreSQL DDL
-- Aligns with .cursor/rules/compensation-registry.mdc (DATABASE SCHEMA).
-- Uses built-in gen_random_uuid() (PostgreSQL 13+).

CREATE TABLE companies (
  company_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  canonical_name TEXT NOT NULL,
  canonical_domain TEXT,
  careers_url TEXT,
  ats_type TEXT NOT NULL,
  ats_board_token TEXT,
  metro TEXT,
  industry TEXT,
  size_band TEXT,
  polling_tier INTEGER NOT NULL,
  last_successful_poll TIMESTAMPTZ,
  salary_transparency TEXT,
  role_family_tags TEXT[],
  CONSTRAINT companies_ats_type_check CHECK (
    ats_type IN (
      'greenhouse',
      'lever',
      'ashby',
      'workday',
      'icims',
      'indeed_only',
      'unknown'
    )
  ),
  CONSTRAINT companies_industry_check CHECK (
    industry IN (
      'tech',
      'fintech',
      'healthcare',
      'industrial',
      'manufacturing',
      'other'
    )
  ),
  CONSTRAINT companies_size_band_check CHECK (
    size_band IN ('seed', 'series_a_c', 'growth', 'public', 'enterprise')
  ),
  CONSTRAINT companies_polling_tier_check CHECK (polling_tier IN (1, 2, 3, 99)),
  CONSTRAINT companies_salary_transparency_check CHECK (
    salary_transparency IN ('high', 'medium', 'low', 'unknown')
  )
);

CREATE TABLE snapshots (
  snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies (company_id) ON DELETE CASCADE,
  observed_at TIMESTAMPTZ NOT NULL,
  source_url TEXT,
  raw_payload BYTEA,
  job_count INTEGER
);

CREATE TABLE postings (
  posting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  snapshot_id UUID NOT NULL REFERENCES snapshots (snapshot_id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies (company_id) ON DELETE CASCADE,
  external_id TEXT NOT NULL,
  title_raw TEXT,
  title_normalized TEXT,
  level_code TEXT,
  role_family TEXT NOT NULL,
  location_raw TEXT,
  metro_normalized TEXT,
  is_remote BOOLEAN,
  salary_min_raw TEXT,
  salary_min_usd INTEGER,
  salary_max_raw TEXT,
  salary_max_usd INTEGER,
  salary_midpoint_usd INTEGER GENERATED ALWAYS AS (
    CASE
      WHEN salary_min_usd IS NOT NULL AND salary_max_usd IS NOT NULL THEN
        (salary_min_usd + salary_max_usd) / 2
      ELSE NULL
    END
  ) STORED,
  salary_spread_pct NUMERIC GENERATED ALWAYS AS (
    CASE
      WHEN
        salary_min_usd IS NOT NULL
        AND salary_min_usd > 0
        AND salary_max_usd IS NOT NULL
        THEN ((salary_max_usd - salary_min_usd)::NUMERIC / salary_min_usd) * 100
      ELSE NULL
    END
  ) STORED,
  multi_level_range BOOLEAN GENERATED ALWAYS AS (
    CASE
      WHEN
        salary_min_usd IS NOT NULL
        AND salary_min_usd > 0
        AND salary_max_usd IS NOT NULL
        AND ((salary_max_usd - salary_min_usd)::NUMERIC / salary_min_usd) * 100 > 60
        THEN TRUE
      ELSE FALSE
    END
  ) STORED,
  salary_source TEXT NOT NULL,
  comp_type_tag TEXT NOT NULL,
  transparency_quality TEXT NOT NULL,
  description_hash TEXT,
  first_observed_at TIMESTAMPTZ NOT NULL,
  last_observed_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  version_number INTEGER NOT NULL DEFAULT 1,
  source_type TEXT NOT NULL DEFAULT 'company_career_page',
  CONSTRAINT postings_role_family_check CHECK (
    role_family IN (
      'swe',
      'infra',
      'data',
      'tpm',
      'pm',
      'em',
      'recruiting',
      'it_network',
      'controls_industrial'
    )
  ),
  CONSTRAINT postings_salary_source_check CHECK (
    salary_source IN ('structured_api', 'parsed_description', 'absent')
  ),
  CONSTRAINT postings_comp_type_tag_check CHECK (
    comp_type_tag IN (
      'base_only',
      'base_ote_mentioned',
      'base_bonus_equity_mentioned'
    )
  ),
  CONSTRAINT postings_transparency_quality_check CHECK (
    transparency_quality IN ('exact_range', 'vague', 'absent')
  ),
  CONSTRAINT postings_status_check CHECK (status IN ('active', 'presumed_closed')),
  CONSTRAINT postings_source_type_check CHECK (
    source_type IN ('company_career_page', 'board')
  )
);

CREATE INDEX idx_snapshots_company_observed ON snapshots (company_id, observed_at DESC);

CREATE INDEX idx_postings_company_external_version ON postings (
  company_id,
  external_id,
  version_number DESC
);

CREATE INDEX idx_postings_company_family ON postings (company_id, role_family);
