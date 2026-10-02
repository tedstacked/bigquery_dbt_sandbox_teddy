{{ config(materialized='table') }}

select date_day
from unnest(generate_date_array(date '2025-01-01', date '2027-12-31', interval 1 day)) as date_day
