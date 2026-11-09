{% macro repro_140574_check(ci_schema, prod_schema, hours=6, region='region-us') %}
  {#- ZD #140574: count the rows the compare column-diff join produces, using the
      same key expression as dbt-compare's _generate_null_safe_surrogate_key,
      then list the BigQuery jobs that touched the CI schema. Run on Core. -#}
  {%- set models = ['repro_140574_nulls_5k', 'repro_140574_nulls_10k', 'repro_140574_nulls_20k', 'repro_140574_control'] -%}
  {%- set null_marker = "'_dbt_dbt_compare_macros_surrogate_key_null_'" -%}
  {%- set key_expr = dbt.hash(dbt.concat(["coalesce(cast(" ~ adapter.quote('id') ~ " as " ~ dbt.type_string() ~ "), " ~ null_marker ~ ")"])) -%}
  {{ log('KEY_EXPR ' ~ key_expr, info=true) }}

  {%- for m in models %}
    {%- set ci_rel = api.Relation.create(database=target.project, schema=ci_schema, identifier=m) -%}
    {%- set prod_rel = api.Relation.create(database=target.project, schema=prod_schema, identifier=m) -%}
    {%- set sql -%}
      with a as (select {{ key_expr }} as k from {{ ci_rel }}),
           b as (select {{ key_expr }} as k from {{ prod_rel }})
      select
        (select count(*) from a) as ci_rows,
        (select count(*) from b) as prod_rows,
        (select count(distinct k) from a) as ci_distinct_keys,
        (select count(*) from a inner join b on a.k = b.k) as joined_rows
    {%- endset -%}
    {%- set r = run_query(sql) -%}
    {%- set row = r.rows[0] -%}
    {{ log('JOIN_CHECK model=' ~ m ~ ' ci_rows=' ~ row[0] ~ ' prod_rows=' ~ row[1] ~ ' ci_distinct_keys=' ~ row[2] ~ ' joined_rows=' ~ row[3], info=true) }}
  {%- endfor %}

  {%- set jobs_sql -%}
    select
      job_id,
      format_timestamp('%H:%M:%S', start_time) as started_utc,
      timestamp_diff(end_time, start_time, millisecond) as duration_ms,
      total_slot_ms,
      total_bytes_processed,
      state,
      ifnull(error_result.reason, '') as error_reason,
      ifnull(regexp_extract(query, r'(repro_140574_(?:nulls_[0-9]+k|control))'), '') as model,
      case
        when query like '%ci_distinct_keys%' then 'repro_check'
        when query like '%dbt_audit_surrogate_key%' and query like '%has_difference%' then 'columns_differ'
        when query like '%nonunique_pk%' then 'classify_rows'
        when query like '%dbt_audit_surrogate_key%' then 'other_keyed'
        else 'other'
      end as query_kind,
      query
    from `{{ region }}`.INFORMATION_SCHEMA.JOBS_BY_USER
    where creation_time > timestamp_sub(current_timestamp(), interval {{ hours }} hour)
      and query like '%{{ ci_schema }}%'
      and query not like '%INFORMATION_SCHEMA.JOBS%'
    order by start_time
  {%- endset -%}
  {%- set jr = run_query(jobs_sql) -%}
  {{ log('JOBS count=' ~ (jr.rows | length), info=true) }}
  {%- set shown = [] -%}
  {%- for row in jr.rows %}
    {{ log('JOB ' ~ row['started_utc'] ~ ' kind=' ~ row['query_kind'] ~ ' model=' ~ row['model'] ~ ' duration_ms=' ~ row['duration_ms'] ~ ' slot_ms=' ~ row['total_slot_ms'] ~ ' bytes=' ~ row['total_bytes_processed'] ~ ' state=' ~ row['state'] ~ ' err=' ~ row['error_reason'] ~ ' job_id=' ~ row['job_id'], info=true) }}
    {%- if row['query_kind'] == 'columns_differ' and row['model'] == 'repro_140574_nulls_20k' and shown | length == 0 %}
      {%- do shown.append(1) -%}
      {{ log('COLUMNS_DIFFER_SQL_BEGIN\n' ~ row['query'][:6000] ~ '\nCOLUMNS_DIFFER_SQL_END', info=true) }}
    {%- endif %}
  {%- endfor %}
{% endmacro %}
