{{ config(materialized='ephemeral') }}

-- Reads the ACTUAL BigQuery priority for the repro_batch_priority build job.
-- Connection is set to priority=batch, so if the engine honors it, priority = 'BATCH'.
select
  job_id,
  priority,
  statement_type,
  creation_time,
  substr(query, 0, 70) as query_snippet
from `region-us`.INFORMATION_SCHEMA.JOBS_BY_USER
where creation_time > timestamp_sub(current_timestamp(), interval 30 minute)
  and job_type = 'QUERY'
  and lower(query) like '%repro_batch_priority%'
  and lower(query) not like '%information_schema%'
order by creation_time desc
limit 25
