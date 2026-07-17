with flattened_table as (
    select
        emp_json:employee_id::varchar                as employee_id,
        emp_json:first_name::varchar                 as first_name,
        emp_json:last_name::varchar                  as last_name,
        emp_json:email::varchar                      as email,
        emp_json:phone::varchar                      as phone,

        emp_json:date_of_birth::varchar            as date_of_birth,
        emp_json:hire_date::varchar                as hire_date,
        emp_json:last_modified_date::varchar       as last_modified_date,

        emp_json:department::varchar                as department,
        emp_json:role::varchar                      as role_col,
        emp_json:employment_status::varchar         as employment_status,
        emp_json:manager_id::varchar                as manager_id,
        emp_json:work_location::varchar             as work_location,

        emp_json:salary::number(10,2)              as salary,
        emp_json:performance_rating::float         as performance_rating,
        emp_json:current_sales::number(10,2)       as current_sales,
        emp_json:sales_target::number(10,2)        as sales_target,

        emp_json:education::varchar                 as education,

        emp_json:address.city::varchar              as city,
        emp_json:address.state::varchar             as state,
        emp_json:address.street::varchar            as street,
        emp_json:address.zip_code::varchar          as zip_code,

        emp_json:certifications                    as certifications,

        _loaded_at
    from {{ ref('Employee_snap') }}
    where employee_id is not null
),

cleaned_and_cast as (
    select
        employee_id,

        coalesce(initcap(trim(first_name)), 'Unknown') as first_name,
        coalesce(initcap(trim(last_name)), 'Unknown') as last_name,

        {{ full_name('first_name', 'last_name') }} as full_name,
        {{ clean_email('email') }} as email,
        {{ clean_phone('phone') }} as phone,

        {{ standardize_date('hire_date')}} as hire_date,
        CASE
            WHEN YEAR({{ standardize_date('hire_date') }}) = 1900 THEN -1
            ELSE DATEDIFF(
                year,
                {{ standardize_date('hire_date') }},
                CURRENT_DATE()
            ) - 1
        END AS tenure,
        
        {{ standardize_date('date_of_birth')}} as date_of_birth,
        {{ standardize_date('last_modified_date')}} as last_modified_date,

        case
            when lower(trim({{ 'role_col' }})) = 'Sales Associate' then 'Associate'
            when lower(trim({{ 'role_col' }})) = 'Store Manager' then 'Manager'
            when lower(trim({{ 'role_col' }})) = 'Senior Manager' then 'Senior Manager'
            else lower(trim({{ 'role_col' }}))
        end
        as job_role,

        -- Perfomance Metrics
        case
            when sales_target > 0
            then (current_sales/sales_target)*100
            else null
        end
        as target_achievement_percentage,

        _loaded_at,

        work_location

    from flattened_table
),

employee_order_metrics as (
    select
        employee_id,
        count(distinct order_id) as orders_processed,
        sum(total_amount) as total_sales_amount

    from {{ ref('Orders_table') }}
    group by employee_id
),

employee_final as (
    select
        e.*,

        coalesce(o.orders_processed,0)
        as orders_processed,

        coalesce(o.total_sales_amount,0)
        as total_sales_amount

    from cleaned_and_cast as e
    left join employee_order_metrics o
        on e.employee_id = o.employee_id
)

select *
from employee_final
qualify row_number() over (
    partition by employee_id
    order by _loaded_at desc
) = 1