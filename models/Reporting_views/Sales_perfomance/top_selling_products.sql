 
SELECT
    prd.product_name,
    prd.category,
    prd.subcategory,
 
    SUM(fct.quantity) AS total_quantity_sold,
    SUM(fct.total_sales_amount) AS total_sales,
    SUM(fct.profit_amount) AS total_profit
 
FROM {{ ref('Fact_sales') }} fct
 
JOIN {{ ref('Dim_product') }}  prd
    ON fct.product_key = prd.product_key
 
GROUP BY
    prd.product_name,
    prd.category,
    prd.subcategory
 
ORDER BY SUM(fct.quantity) DESC
 