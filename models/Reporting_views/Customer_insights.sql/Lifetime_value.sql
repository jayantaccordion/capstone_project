SELECT
 
    cust.customer_id,
    cust.full_name,
    cust.customer_segment,
 
    SUM(fct.total_sales_amount) AS lifetime_value,
    SUM(fct.profit_amount) AS lifetime_profit,
    COUNT(DISTINCT fct.order_id) AS purchase_count
 
FROM {{ ref('Fact_sales') }} fct
 
JOIN {{ ref('Dim_customer') }} cust
    ON fct.customer_key = cust.customer_key
 
GROUP BY
    cust.customer_id,
    cust.full_name,
    cust.customer_segment
 