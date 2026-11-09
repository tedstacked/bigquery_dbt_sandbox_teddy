-- ZD #140574 repro: 10,000 unique ids plus 10,000 NULL ids.
-- id has only a `unique` test, so primary key inference picks it,
-- and the test passes because `unique` skips NULLs.
-- PR change for the CI compare repro: this comment only, the data is identical.
{{ config(materialized='table') }}

select id, 'unique_key' as row_kind
from unnest(generate_array(1, 10000)) as id

union all

select cast(null as int64) as id, 'null_key' as row_kind
from unnest(generate_array(1, 10000))
