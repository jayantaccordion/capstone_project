{% snapshot Product_snap %}
{{
    config(
      unique_key='product_id'
    )
}}
 
with flattened as (
    
    select
        file_last_modified,
        _loaded_at,
        _batch_id,
        _source_file,
        prd.value:product_id::varchar as product_id,
        prd.value as prd_json

    from {{ ref('Bronze_product_data') }},
    lateral flatten(input => raw_json_payload:products_data) prd
)
 
select * 
from flattened
qualify row_number() over (
    partition by product_id
    order by file_last_modified desc, _loaded_at desc
) = 1
 
{% endsnapshot %}
 
 