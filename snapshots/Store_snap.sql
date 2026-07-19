{% snapshot Store_snap %}
{{
    config(
      unique_key='store_id'
    )
}}
 
with flattened as (
    select
        sto.value:store_id::varchar as store_id,
        sto.value as sto_json,
        _SOURCE_FILE,
        _LOADED_AT,
        _BATCH_ID,
        FILE_LAST_MODIFIED

    from {{ ref('Store_data') }},
    lateral flatten(input => raw_json_payload:stores_data) sto
)
 
select * 
from flattened
 
{% endsnapshot %}
 
 