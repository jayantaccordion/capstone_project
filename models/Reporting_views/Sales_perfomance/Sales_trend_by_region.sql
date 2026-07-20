select
    sto.region,
    dat.year,
    dat.month_number,
    dat.month_name,
    count(distinct sales.sales_key) as total_transactions,
    sum(sales.total_sales_amount) as total_sales_amount,
    sum(sales.profit_amount) as total_profit_amount,
    avg(sales.total_sales_amount) as average_order_value

from {{ ref('Fact_sales') }} sales
left join {{ ref('Dim_store') }} sto
    on sales.store_key = sto.store_key
left join {{ ref('Dim_date') }} dat
    on sales.date_key = dat.date_key

group by
    sto.region,
    dat.year,
    dat.month_number,
    dat.month_name

order by
    sto.region