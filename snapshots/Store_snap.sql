
{% snapshot Store_snap %}
 
{{
    config(
      unique_key='store_id',
    )
}}
 
with unwrapped as (
    select
        st.value                        as store_json,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from {{ ref('Bronze_store_data') }},
         lateral flatten(input => raw_json_payload:stores_data) st
),
 
extracted as (
    select
        store_json:store_id::string       as store_id,
        store_json                         as sto_json,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from unwrapped
),
 
cleaned as (
    select
        *
    from extracted
)
 
select *
from cleaned
where store_id is not null
  and store_id != ''
qualify row_number() over (
    partition by store_id
    order by file_last_modified desc, _loaded_at desc
) = 1
 
{% endsnapshot %}
 
 
 