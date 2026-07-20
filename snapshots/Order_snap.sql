{% snapshot Order_snap %}
{{
    config(
      unique_key='order_id'
    )
}}
 
with flattened as (
    select
        file_last_modified,
        _loaded_at,
        _batch_id,
        _source_file,
        ord.value:order_id::varchar as order_id,
        ord.value as ord_json

    from {{ ref('Bronze_orders_data') }},
    lateral flatten(input => raw_json_payload:orders_data) ord
)
 
select * 
from flattened
 
{% endsnapshot %}
 
 