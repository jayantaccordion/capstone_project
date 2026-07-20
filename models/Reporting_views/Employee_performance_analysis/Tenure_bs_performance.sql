select
    emp.tenure,
    count(distinct emp.employee_id) as total_employees,
    count(distinct fct.order_id) as total_orders,
    sum(fct.quantity) as total_quantity_sold,
    round(
        sum(fct.total_sales_amount),
        2
    ) as total_sales,
    round(
        sum(fct.cost_amount),
        2
    ) as total_cost,
    round(
        sum(fct.item_discount_amount),
        2
    ) as total_discount,
    round(
        sum(fct.profit_amount),
        2
    ) as total_profit,
    round(
        avg(fct.total_sales_amount),
        2
    ) as average_sales_per_order,
    round(
        avg(emp.performance_rating),
        2
    ) as average_performance_rating,
    round(
        (
            sum(fct.profit_amount)
            /
            nullif(sum(fct.total_sales_amount),0)
        ) * 100,
        2
    ) as profit_margin_percentage
from {{ ref('Fact_sales') }} fct

left join {{ ref('Dim_employee') }} emp
    on fct.employee_key = emp.employee_key
 
group by emp.tenure
order by emp.tenure
 