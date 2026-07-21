with final_order_table as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'ord.order_id',
            'itm.product_id',
        ]) }} ord_key,
        ord.*,
        itm.product_id,
        itm.quantity,
        itm.unit_price,
        itm.cost_price,
        itm.item_discount_amount,

        sum(itm.quantity * itm.unit_price * (100 - itm.item_discount_amount))
        over(partition by ord.order_id) 
        as line_revenue,

        sum(itm.quantity * itm.cost_price)
        over(partition by ord.order_id) 
        as line_cost,

        count(itm.product_id)
        over(partition by ord.order_id) 
        as total_items,

        sum(itm.quantity)
        over(partition by ord.order_id) 
        as total_quantity,

        sum(itm.quantity * itm.unit_price)
        over(partition by ord.order_id) 
        as calculated_total_amount,

        sum(itm.quantity * itm.cost_price)
        over(partition by ord.order_id) 
        as total_cost,

        sum(itm.item_discount_amount)
        over(partition by ord.order_id) 
        as total_discount

    from {{ ref('Silver_order_table')}} ord
    left join {{ ref('Silver_items_table')}} itm
        on ord.order_id = itm.order_id
),

profit_metrics as (
    select *,
        (
            line_revenue
            * (100 - orders_discount_amount)
            - line_cost
            - shipping_cost
            - tax_amount
        ) as profit_amount,

        case
            when line_revenue > 0
            then
                (
                    (
                        line_revenue
                        * (100 - orders_discount_amount)
                        - line_cost
                        - shipping_cost
                        - tax_amount
                    )
                    / line_revenue
                ) * 100
            else null
        end as profit_margin_percentage
    from final_order_table
)

select *
from profit_metrics
qualify row_number() over (
    partition by ord_key
    order by _loaded_at desc
) = 1
