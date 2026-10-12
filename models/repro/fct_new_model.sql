-- ZD136396: brand-new model in the same PR; the only node state:new should select.
select id, val from {{ ref('stg_repro_input') }}
