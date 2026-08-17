# Repro: ticket #133930 — model version deprecation warning

Reproduces the `UpcomingReferenceDeprecation` warning emitted during `dbt build`
when a model references a versioned model version that has a future
`deprecation_date`.

`customer_se` refs `customer` v1, which is slated for deprecation on 2027-01-01.

## Behavior verified locally on dbt Core 1.6.13

- `dbt build` -> logs `[WARNING] ... slated for deprecation ...`, exit code 0
  (job succeeds, so no failure notification fires).
- `dbt --warn-error-options '{"include": ["UpcomingReferenceDeprecation"]}' build`
  -> Compilation Error, exit code 2 (job fails -> failure notification fires).
  NOTE (1.6): `--warn-error-options` is a GLOBAL flag and must come BEFORE the
  subcommand, or be set via env var `DBT_WARN_ERROR_OPTIONS`.
