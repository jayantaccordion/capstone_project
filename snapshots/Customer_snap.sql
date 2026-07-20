{% snapshot Customer_snap %}
{{
    config(
      unique_key='customer_id'
    )
}}

with flattened as (
    select
        file_last_modified,
        _loaded_at,
        _batch_id,
        _source_file,
        cust.value:customer_id::varchar as customer_id,
        cust.value as cust_json
    from {{ ref('Bronze_customers_data') }},
    lateral flatten(input => raw_json_payload:customers_data) cust
),

deduped as (
    select *
    from flattened
    qualify row_number() over (
        partition by customer_id
        order by file_last_modified desc, _loaded_at desc
    ) = 1
)

select *
from deduped

{% endsnapshot %}