{% snapshot Store_snap %}
{{
    config(
      unique_key='store_id'
    )
}}
 
with flattened as (
    select
        file_last_modified,
        _loaded_at,
        _batch_id,
        _source_file,
        sto.value:store_id::varchar as store_id,
        sto.value as sto_json

    from {{ ref('Bronze_store_data') }},
    lateral flatten(input => raw_json_payload:stores_data) sto
)
 
select * 
from flattened
qualify row_number() over (
    partition by store_id
    order by file_last_modified desc, _loaded_at desc
) = 1
 
{% endsnapshot %}
 
 