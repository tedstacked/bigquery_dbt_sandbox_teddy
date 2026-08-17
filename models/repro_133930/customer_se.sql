-- references the deprecated v1 of the versioned model, mirroring ticket #133930
select * from {{ ref('customer', v=1) }}
