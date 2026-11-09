-- ZD #140574 repro: 10,000 unique ids plus 20,000 NULL ids.
-- id has only a `unique` test, so primary key inference picks it,
-- and the test passes because `unique` skips NULLs.
{{ config(materialized='table') }}

select id, 'unique_key' as row_kind
from unnest(generate_array(1, 10000)) as id

union all

select cast(null as int64) as id, 'null_key' as row_kind
from unnest(generate_array(1, 20000))
