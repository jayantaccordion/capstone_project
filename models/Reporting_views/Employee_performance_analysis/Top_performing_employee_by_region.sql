with employee_sales as (
    select
        sto.region,
        emp.employee_id,
        emp.full_name,
        emp.job_role,
        count(distinct fct.order_id) as total_orders,
        sum(fct.quantity) as total_quantity_sold,
        round(sum(fct.total_sales_amount),2) as total_sales,
        round(avg(fct.total_sales_amount),2) as average_order_value
 
    from {{ ref('Fact_sales') }} fct
 
    left join {{ ref('Dim_employee') }} emp
        on fct.employee_key = emp.employee_key
 
    left join {{ ref('Dim_store') }} sto
        on fct.store_key = sto.store_key
 
    group by
        sto.region,
        emp.employee_id,
        emp.full_name,
        emp.job_role
),
 
ranked_employees as (
    select
        *,
        dense_rank() over (
            partition by region
            order by total_sales desc
        ) as employee_rank
    from employee_sales
)
 
select
    region,
    employee_id,
    full_name,
    job_role,
    total_orders,
    total_quantity_sold,
    total_sales,
    average_order_value
from ranked_employees
where employee_rank = 1
order by region
 