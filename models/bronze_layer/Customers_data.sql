{{ create_external_table('customer_ext', 'customer_data') }}
 
select
    metadata$filename                   as _source_file,
    current_timestamp()::timestamp_ntz   as _loaded_at,
    '{{ invocation_id }}'               as _batch_id,
    value:updated_at::timestamp         as file_last_modified,
    value                               as raw_json_payload
 
from AZURE_RAW.customer_ext
 
{% if is_incremental() %}
  where value:updated_at::timestamp > (select max(file_last_modified) from {{ this }})
{% endif %}