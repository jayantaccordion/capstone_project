{{ create_external_table('employee_ext', 'employee_data') }}
select
    metadata$filename                   as _source_file,
    current_timestamp()::timestamp_ntz   as _loaded_at,
    '{{ invocation_id }}'               as _batch_id,
    updated_at       as file_last_modified,
    value                               as raw_json_payload
 
from {{ source('AZURE_RAW', 'employee_ext') }}
 
{% if is_incremental() %}
  where value:updated_at::timestamp > (select max(file_last_modified) from {{ this }})
{% endif %}