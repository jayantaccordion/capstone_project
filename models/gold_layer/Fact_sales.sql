select
    {{ dbt_utils.generate_surrogate_key([
        'ord.order_id',
        'prd.product_id'
    ]) }} as sales_key,
    ord.order_id,

    cust.customer_key,
    prd.product_key,
    sto.store_key,
    emp.employee_key,
    dat.date_key,

    ord.quantity,
    ord.unit_price,

    (ord.quantity * ord.unit_price) as total_sales_amount,
    (ord.quantity * prd.cost_price) as cost_amount,
    ord.item_discount_amount,

    ord.shipping_cost,
    (
        (ord.quantity * ord.unit_price)
        -
        (ord.quantity * prd.cost_price)
        -
        ord.item_discount_amount
        -
        ord.shipping_cost
    ) as profit_amount,

    sto.region,

    case
        when upper(ord.order_source) like '%ONLINE%'
            then 'Online'
        else 'In-Store'
    end as sales_channel,

    cust.customer_segment

from {{ ref('Orders_table') }} ord

left join {{ ref('Dim_customer') }} cust
    on ord.customer_id = cust.customer_id
   and cust.is_current = true

left join {{ ref('Dim_product') }} prd
    on ord.product_id = prd.product_id


left join {{ ref('Dim_store') }} sto
    on ord.store_id = sto.store_id

left join {{ ref('Dim_employee') }} emp
    on ord.employee_id = emp.employee_id

left join {{ ref('Dim_date') }} dat
    on ord.order_date = dat.full_date