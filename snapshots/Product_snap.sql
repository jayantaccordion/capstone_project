{% snapshot Product_snap %}
{{
    config(
      unique_key='product_id'
    )
}}
 
with flattened as (
    select
        prd.value:product_id::varchar as product_id,
        prd.value as prd_json,
        _SOURCE_FILE,
        _LOADED_AT,
        _BATCH_ID,
        FILE_LAST_MODIFIED

    from {{ ref('Product_data') }},
    lateral flatten(input => raw_json_payload:products_data) prd
)
 
select * 
from flattened
 
{% endsnapshot %}
 
 