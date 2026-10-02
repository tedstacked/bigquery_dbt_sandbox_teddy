{{ config(materialized='table') }}

-- 30 synthetic orders, one per day starting 2026-01-02
select
    order_id,
    date_add(date '2026-01-01', interval order_id day) as ordered_at,
    cast(order_id * 10 as numeric) as amount
from unnest(generate_array(1, 30)) as order_id
