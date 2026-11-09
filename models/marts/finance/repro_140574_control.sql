-- ZD #140574 control: the same 30,000-row shape as repro_140574_nulls_20k,
-- but the 20,000 extra rows get unique negative ids instead of NULL.
{{ config(materialized='table') }}

select id, 'unique_key' as row_kind
from unnest(generate_array(1, 10000)) as id

union all

select -n as id, 'negative_key' as row_kind
from unnest(generate_array(1, 20000)) as n
