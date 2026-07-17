with flattened_order_items as (
    select
        order_id::varchar                              as order_id,
        item.value:product_id::varchar                                  as product_id,
        coalesce(item.value:quantity::number,0)                         as quantity,
        coalesce(item.value:unit_price::number(10,2),0)                 as unit_price,
        coalesce(item.value:cost_price::number(10,2),0)                 as cost_price,
        coalesce(item.value:item_discount_amount::number(10,2),0)       as item_discount_amount

    from {{ ref('Order_snap') }},
    lateral flatten(
        input => ord_json:order_items
    ) item
)

select *
from flattened_order_items