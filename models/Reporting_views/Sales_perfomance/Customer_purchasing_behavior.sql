select
    cust.customer_id,
    cust.full_name,
    cust.customer_segment,

    count(distinct fct.order_id) as total_orders,
    sum(fct.quantity) as total_quantity_purchased,
    round(
        sum(fct.total_sales_amount),
        2
    ) as lifetime_value,
    round(
        avg(fct.total_sales_amount),
        2
    ) as average_order_value,
    round(
        sum(fct.profit_amount),
        2
    ) as lifetime_profit,
 
    min(dat.full_date) as first_purchase_date,
    max(dat.full_date) as last_purchase_date,
 
    datediff(
        day,
        min(dat.full_date),
        max(dat.full_date)
    ) as customer_lifetime_days,
 
    dense_rank() over (
        order by
            sum(fct.total_sales_amount) desc
    ) as customer_rank
 
from {{ ref('Fact_sales') }} fct
 
left join {{ ref('Dim_customer') }} cust
    on fct.customer_key = cust.customer_key
 
left join {{ ref('Dim_date') }} dat
    on fct.date_key = dat.date_key
 
group by
    cust.customer_id,
    cust.full_name,
    cust.customer_segment
 
order by
    lifetime_value desc
 