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
        file_last_modified,
        _loaded_at,
        _batch_id,
        _source_file
    from {{ ref('Bronze_employee_data') }},
    lateral flatten(input => raw_json_payload:employees_data) emp
)
 
select * 
from flattened
qualify row_number() over (
    partition by employee_id
    order by file_last_modified desc, _loaded_at desc
) = 1
 
{% endsnapshot %}
 
 