 
SELECT
 
    cust.customer_segment,
    COUNT(DISTINCT cust.customer_id) AS total_customers,
    SUM(fct.total_sales_amount) AS total_sales,
    AVG(fct.total_sales_amount) AS avg_order_value,
    SUM(fct.profit_amount) AS profit
 
FROM {{ ref('Fact_sales') }} fct
JOIN {{ ref('Dim_customer') }} cust
ON fct.customer_key = cust.customer_key
GROUP BY
    cust.customer_segment
 