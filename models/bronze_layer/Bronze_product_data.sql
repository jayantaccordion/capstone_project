{{ create_external_table('product_ext', 'product_data') }}

select
    metadata$filename                   as _source_file,
    current_timestamp()::timestamp_ntz  as _loaded_at,
    '{{ invocation_id }}'               as _batch_id,
    metadata$file_last_modified         as file_last_modified,
    value                               as raw_json_payload
 
from {{ source('AZURE_RAW', 'product_ext') }}
 
{% if is_incremental() %}
  where metadata$file_last_modified > (select max(file_last_modified) from {{ this }})
{% endif %}