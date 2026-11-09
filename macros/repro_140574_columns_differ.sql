{% macro repro_140574_columns_differ(ci_schema, prod_schema, model='repro_140574_nulls_distinct_val', columns=['id', 'val']) %}
  {#- ZD #140574: run the same column-diff query that compare logs (a = deferred/prod,
      b = CI, inner join on the NULL-coalescing surrogate key) and print its result. -#}
  {%- set a_rel = api.Relation.create(database=target.project, schema=prod_schema, identifier=model) -%}
  {%- set b_rel = api.Relation.create(database=target.project, schema=ci_schema, identifier=model) -%}
  {%- set key = "to_hex(md5(cast(coalesce(cast(`id` as string), '_dbt_dbt_compare_macros_surrogate_key_null_') as string))) as dbt_audit_surrogate_key" -%}
  {%- set col_list = [] -%}
  {%- for c in columns %}{% do col_list.append('`' ~ c ~ '`') %}{% endfor -%}
  {%- set sql -%}
with a as (
    select {{ col_list | join(', ') }}, {{ key }}
    from (select * from {{ a_rel }}) as a_subq
),
b as (
    select {{ col_list | join(', ') }}, {{ key }}
    from (select * from {{ b_rel }}) as b_subq
),
calculated as (
    select
    {%- for c in columns %}
        logical_or(
            (
                (a.`{{ c }}` != b.`{{ c }}`)
                or (a.`{{ c }}` is null and b.`{{ c }}` is not null)
                or (a.`{{ c }}` is not null and b.`{{ c }}` is null)
            )
        ) as {{ c }}_has_difference{{ ',' if not loop.last }}
    {%- endfor %}
    from a
    inner join b on a.dbt_audit_surrogate_key = b.dbt_audit_surrogate_key
)
{%- for c in columns %}
select '{{ c }}' as column_name, {{ c }}_has_difference as has_difference from calculated
{{ 'union all' if not loop.last }}
{%- endfor %}
  {%- endset -%}
  {{ log('COLUMNS_DIFFER_SQL_BEGIN\n' ~ sql ~ '\nCOLUMNS_DIFFER_SQL_END', info=true) }}
  {%- set r = run_query(sql) -%}
  {%- for row in r.rows %}
    {{ log('COLUMNS_DIFFER_RESULT model=' ~ model ~ ' column=' ~ row[0] ~ ' has_difference=' ~ row[1], info=true) }}
  {%- endfor %}
  {%- set ident -%}
    select
      (select count(*) from (select * from {{ a_rel }} except distinct select * from {{ b_rel }})) as only_in_prod,
      (select count(*) from (select * from {{ b_rel }} except distinct select * from {{ a_rel }})) as only_in_ci
  {%- endset -%}
  {%- set ir = run_query(ident) -%}
  {{ log('IDENTITY model=' ~ model ~ ' rows_only_in_prod=' ~ ir.rows[0][0] ~ ' rows_only_in_ci=' ~ ir.rows[0][1], info=true) }}
{% endmacro %}
