with product_sales as (
    select
        prd.subcategory,
        sum(fct.total_sales_amount) as total_sales

    from {{ ref('Fact_sales') }} fct
    left join {{ ref('Dim_product') }} prd
        on fct.product_key = prd.product_key
    group by
        prd.subcategory
)

select
    subcategory,
    total_sales
from product_sales
order by total_sales desc