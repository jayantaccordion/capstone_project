with final_order_table as (
    select
        o.*,
        i.product_id,
        i.quantity,
        i.unit_price,
        i.cost_price,
        i.item_discount_amount,

        sum(
            i.quantity
            * i.unit_price
            * (1 - i.item_discount_amount/100)
        )
        over(
            partition by o.order_id
        ) as line_revenue,

        sum(
            i.quantity
            * i.cost_price
        )
        over(
            partition by o.order_id
        ) as line_cost,

        count(i.product_id)
        over(
            partition by o.order_id
        ) as total_items,

        sum(i.quantity)
        over(
            partition by o.order_id
        ) as total_quantity,

        sum(
            i.quantity * i.unit_price
        )
        over(
            partition by o.order_id
        ) as calculated_total_amount,


        sum(
            i.quantity * i.cost_price
        )
        over(
            partition by o.order_id
        ) as total_cost,


        sum(i.item_discount_amount)
        over(
            partition by o.order_id
        ) as total_discount

    from {{ ref('Order_table')}} o
    left join {{ ref('Order_items_table')}} i
        on o.order_id = i.order_id
),

profit_metrics as (
    select *,
        (
            line_revenue
            * (1 - orders_discount_amount/100)
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
/*qualify row_number() over (
    partition by order_id
    order by _loaded_at desc
) = 1 */