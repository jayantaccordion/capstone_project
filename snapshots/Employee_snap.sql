{% snapshot Employee_snap %}
{{
    config(
      unique_key='employee_id'
    )
}}
 
with flattened as (
    select
        file_last_modified,
        _loaded_at,
        _batch_id,
        _source_file,
        emp.value:employee_id::varchar as employee_id,
        emp.value as emp_json
    from {{ ref('Bronze_employee_data') }},
    lateral flatten(input => raw_json_payload:employees_data) emp
)
 
select * 
from flattened
 
{% endsnapshot %}
 
 