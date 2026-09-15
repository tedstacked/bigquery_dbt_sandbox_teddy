-- Incremental model-under-test. static_analysis='off' forces the baseline/off
-- path where Fusion resolves the expected-output columns by describing the
-- physical relation in the warehouse instead of inferring from compiled SQL.
{{
  config(
    materialized='incremental',
    unique_key='id',
    static_analysis='off'
  )
}}

select
    id,
    val
from {{ ref('stg_repro_input') }}
{% if is_incremental() %}
where id > (select max(id) from {{ this }})
{% endif %}
