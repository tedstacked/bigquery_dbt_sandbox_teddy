-- ZD #140574 false-positive check: 10,000 unique ids plus 1,000 NULL ids.
-- Every row has a distinct val, and the data is identical on both sides of the compare.
{{ config(materialized='table') }}

select id, id as val
from unnest(generate_array(1, 10000)) as id

union all

select cast(null as int64) as id, 100000 + n as val
from unnest(generate_array(1, 1000)) as n
