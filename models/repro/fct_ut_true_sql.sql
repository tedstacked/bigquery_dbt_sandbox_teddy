-- ZD136396 follow-up: brand-new incremental model, unit tested in
-- is_incremental: true mode. No static_analysis config, so the env default applies.
{{
  config(
    materialized='incremental',
    unique_key='id'
  )
}}

select
    id,
    val
from {{ ref('stg_repro_input') }}
{% if is_incremental() %}
where id > (select max(id) from {{ this }})
{% endif %}
