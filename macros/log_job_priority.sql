{% macro log_job_priority() %}
{% set q %}
select job_id, priority, statement_type, substr(query, 0, 60) as qs, creation_time
from `region-us`.INFORMATION_SCHEMA.JOBS_BY_USER
where creation_time > timestamp_sub(current_timestamp(), interval 3 minute)
  and job_type = 'QUERY'
  and lower(query) like '%repro_batch_priority%'
  and lower(query) not like '%information_schema%'
order by creation_time desc
limit 5
{% endset %}
{% if execute %}
{% set res = run_query(q) %}
{{ log("JOBPRIORITY_ROWS=" ~ (res.rows | length), info=true) }}
{% for row in res.rows %}
{{ log("JOBPRIORITY | priority=" ~ row[1] ~ " | type=" ~ row[2] ~ " | job=" ~ row[0], info=true) }}
{% endfor %}
{% endif %}
{% endmacro %}
