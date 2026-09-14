{{ config(materialized='table') }}

-- Repro for ZD#136210: does the engine honor connection priority=batch on BigQuery?
-- Building this table submits a real BigQuery QUERY job. We then read back the
-- job's recorded priority from INFORMATION_SCHEMA to see if it was BATCH or INTERACTIVE.
select 1 as x, current_timestamp() as built_at
