{% snapshot Employee_snap %}
{{
    config(
      unique_key='employee_id'
    )
}}
 
with flattened as (
    select
        emp.value:employee_id::varchar as employee_id,
        emp.value as emp_json,
        _SOURCE_FILE,
        _LOADED_AT,
        _BATCH_ID,
        FILE_LAST_MODIFIED
    from {{ ref('Employee_data') }},
    lateral flatten(input => raw_json_payload:employees_data) emp
)
 
select * 
from flattened
 
{% endsnapshot %}
 
 