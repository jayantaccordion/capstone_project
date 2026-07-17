{% snapshot Customer_snap %}
{{
    config(
      unique_key='customer_id'
    )
}}
 
with flattened as (
    select
        cust.value:customer_id::varchar as customer_id,
        cust.value as cust_json,
        _SOURCE_FILE,
        _LOADED_AT,
        _BATCH_ID,
        FILE_LAST_MODIFIED
    from {{ ref('Customers_data') }},
    lateral flatten(input => raw_json_payload:customers_data) cust
)
 
select * from flattened
qualify row_number() over (
    partition by customer_id
    order by FILE_LAST_MODIFIED desc, _LOADED_AT desc
) = 1
 
{% endsnapshot %}
 
 