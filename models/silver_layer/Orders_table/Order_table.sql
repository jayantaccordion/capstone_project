with flattened_orders as (
    select

        ord_json:order_id::varchar                    as order_id,
        ord_json:customer_id::varchar                 as customer_id,
        ord_json:employee_id::varchar                 as employee_id,
        ord_json:store_id::varchar                    as store_id,
        ord_json:campaign_id::varchar                 as campaign_id,

        ord_json:created_at::varchar                  as created_at,
        ord_json:order_date::varchar                  as order_date,
        ord_json:delivery_date::varchar               as delivery_date,
        ord_json:estimated_delivery_date::varchar     as estimated_delivery_date,
        ord_json:shipping_date::varchar               as shipping_date,

        ord_json:order_source::varchar                as order_source,
        ord_json:order_status::varchar                as order_status,
        ord_json:payment_method::varchar              as payment_method,
        ord_json:shipping_method::varchar             as shipping_method,

        ord_json:discount_amount::number(10,2)        as orders_discount_amount,
        ord_json:shipping_cost::number(10,2)          as shipping_cost,
        ord_json:tax_amount::number(10,2)             as tax_amount,
        ord_json:total_amount::number(10,2)           as total_amount,

        ord_json:billing_address.city::varchar       as billing_city,
        ord_json:billing_address.state::varchar      as billing_state,
        ord_json:billing_address.street::varchar     as billing_street,
        ord_json:billing_address.zip_code::varchar   as billing_zip_code,

        ord_json:shipping_address.city::varchar      as shipping_city,
        ord_json:shipping_address.state::varchar     as shipping_state,
        ord_json:shipping_address.street::varchar    as shipping_street,
        ord_json:shipping_address.zip_code::varchar  as shipping_zip_code,

        _loaded_at

    from {{ ref('Order_snap') }}
    where ord_json:order_id is not null
),

cleaned_orders as (
    select
        order_id,
        coalesce(customer_id,'UNKNOWN_CUST') as customer_id,
        coalesce(employee_id,'UNKNOWN_EMP') as employee_id,
        coalesce(store_id,'UNKNOWN_STORE') as store_id,
        coalesce(campaign_id,'UNKNOWN_CAMP') as campaign_id,
        upper(trim(order_status)) as order_status,
        initcap(trim(order_source)) as order_source,
        initcap(trim(payment_method)) as payment_method,
        initcap(trim(shipping_method)) as shipping_method,


        {{ standardize_date('created_at') }} as created_at,
        {{ standardize_date('order_date') }} as order_date,
        {{ standardize_date('shipping_date') }} as shipping_date,
        {{ standardize_date('delivery_date') }} as delivery_date,
        {{ standardize_date('estimated_delivery_date') }} as estimated_delivery_date,

        orders_discount_amount,
        shipping_cost,
        tax_amount,
        total_amount,

        coalesce(initcap(trim(billing_street)), 'Unknown Street') as billing_street,
        coalesce(initcap(trim(billing_city)), 'Unknown Street') as billing_city,
        coalesce(upper(trim(billing_state)), 'NA')                as billing_state,
        coalesce(trim(billing_zip_code), '00000')                 as billing_zip_code,
        
        coalesce(initcap(trim(shipping_street)), 'Unknown Street') as shipping_street,
        coalesce(initcap(trim(shipping_city)), 'Unknown City')     as shipping_city,
        coalesce(upper(trim(shipping_state)), 'NA')                as shipping_state,
        coalesce(trim(shipping_zip_code), '00000')                 as shipping_zip_code,

        date_part(hour,
            try_to_timestamp(order_date)
        ) as order_hour,
        date_part(week,
            try_to_date(order_date)
        ) as order_week,
        date_part(month,
            try_to_date(order_date)
        ) as order_month,
        date_part(quarter,
            try_to_date(order_date)
        ) as order_quarter,
        date_part(year,
            try_to_date(order_date)
        ) as order_year,

        coalesce(
            datediff(
                day,
                {{ standardize_date('order_date')}},
                {{ standardize_date('shipping_date')}}
            ),
            -1
        ) as processing_days,


        coalesce(
            datediff(
                day,
                {{ standardize_date('shipping_date')}},
                {{ standardize_date('delivery_date')}}
            ),
            -1
        ) as shipping_days,

        case
            when delivery_date is not null
             and {{ standardize_date('delivery_date')}}
                 <= {{ standardize_date('estimated_delivery_date')}}
                then 'On Time'
            when delivery_date is not null
             and {{ standardize_date('delivery_date')}}
                 > {{ standardize_date('estimated_delivery_date')}}
                then 'Delayed'
            when delivery_date is null
             and current_date()
                 > {{ standardize_date('estimated_delivery_date')}}
                then 'Potentially Delayed'
            else 'In Transit'
        end as delivery_status,

        _loaded_at
    from flattened_orders
),

order_time_of_day as (
    select *,
        case
            when order_hour >= 5 and order_hour < 12 then 'Morning'
            when order_hour >= 12 and order_hour < 17 then 'Afternoon'
            when order_hour >= 17 and order_hour < 22 then 'Evening'
            else 'Night'
        end as order_time_of_day
    from cleaned_orders
)

select *
from order_time_of_day
qualify row_number() over (
    partition by order_id
    order by _loaded_at desc
) = 1 
