{% snapshot Order_snap %}
{{
    config(
      unique_key='order_id'
    )
}}
 
with flattened as (
    select
        ord.value:order_id::varchar as order_id,
        ord.value as ord_json,
        _SOURCE_FILE,
        _LOADED_AT,
        _BATCH_ID,
        FILE_LAST_MODIFIED

    from {{ ref('Orders_data') }},
    lateral flatten(input => raw_json_payload:orders_data) ord
)
 
select * from flattened
qualify row_number() over (
    partition by order_id
    order by FILE_LAST_MODIFIED desc, _LOADED_AT desc
) = 1
 
{% endsnapshot %}
 
 