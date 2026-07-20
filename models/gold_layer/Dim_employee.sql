select
    {{ dbt_utils.generate_surrogate_key(['employee_id']) }} as employee_key,
    employee_id,
    full_name,
    job_role,
    work_location,
    tenure,
    email,
    phone,
    target_achievement_percentage,
    orders_processed,
    total_sales_amount,
    performance_rating

from {{ ref('Silver_employee_table') }}