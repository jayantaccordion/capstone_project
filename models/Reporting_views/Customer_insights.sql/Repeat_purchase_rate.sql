SELECT
 
    cust.customer_id,
    cust.full_name AS customer_name,
    cust.customer_segment,
 
    COUNT(DISTINCT fct.order_id) AS total_orders,
 
    CASE
        WHEN COUNT(DISTINCT fct.order_id) > 1
        THEN TRUE
        ELSE FALSE
    END AS is_repeat_customer
 
 
FROM {{ ref('Fact_sales') }} fct
 
JOIN {{ ref('Dim_customer') }} cust
    ON fct.customer_key = cust.customer_key
 
 
GROUP BY
 
    cust.customer_id,
    cust.full_name,
    cust.customer_segment
 