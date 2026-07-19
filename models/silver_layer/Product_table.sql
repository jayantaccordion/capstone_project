with flattened_table as (
    select
        --Product Description
        prd_json:product_id::varchar         as product_id,
        prd_json:name::varchar               as product_name,
        prd_json:short_description::varchar  as short_desc,
        prd_json:technical_specs::varchar    as tech_specs,
        prd_json:color::varchar              as color,
        prd_json:size::varchar               as size,
        prd_json:brand::varchar              as brand,
       
       --Category
        prd_json:category::varchar           as category,
        prd_json:subcategory::varchar        as subcategory,
        prd_json:product_line::varchar       as product_line,
       
       --Price
        {{ clean_currency('prd_json:unit_price::varchar') }}         as unit_price,
        {{ clean_currency('prd_json:cost_price::varchar') }}         as cost_price,

        --Inventory
        prd_json:stock_quantity::integer     as stock_quantity,
        prd_json:reorder_level::integer      as reorder_level,
       
        --Supplier & Metadata
        prd_json:supplier_id::varchar        as supplier_id,
        prd_json:last_modified_date as last_modified_date,
       
        _loaded_at
    from {{ ref('Product_snap') }}
),
 
cleaned_and_cast as (
    select
        coalesce(product_id, 'UNKNOWN_PROD') as product_id,
       
        -- Attribute
        coalesce(replace(initcap(trim(product_name)), ' ', ''), 'UnknownProduct')      as product_name,
        coalesce(replace(initcap(trim(category)), ' ', ''), 'UnknownCategory')          as category,
        coalesce(replace(initcap(trim(subcategory)), ' ', ''), 'UnknownSubcategory')    as subcategory,
        coalesce(replace(initcap(trim(product_line)), ' ', ''), 'UnknownProductLine')   as product_line,
        coalesce(initcap(trim(brand)), 'Unknown Brand')            as brand,
        coalesce(initcap(trim(size)), 'Unknown Size')            as size,
        coalesce(initcap(trim(color)), 'Unknown Color')            as color,
        coalesce(upper(trim(supplier_id)), 'UNKNOWN_SUP')         as supplier_id,
 
        -- Description
        coalesce(trim(short_desc), 'No description available')     as short_description,
        coalesce(trim(tech_specs), 'No specifications available')  as technical_specs,
        concat(
            coalesce(initcap(trim(product_name)), 'Unknown Product'),
            ' - ',
            coalesce(trim(short_desc), 'No description available'),
            ' (Specs: ',
            coalesce(trim(tech_specs), 'No specifications available'),
            ')'
        ) as product_full_description,
 
        -- Product Hierarchy
        concat_ws(' > ',
            nullif(initcap(trim(category)), ''),
            nullif(initcap(trim(subcategory)), ''),
            nullif(initcap(trim(product_line)), '')
        ) as product_hierarchy,
 
        --Measure
        unit_price,
        cost_price,

        -- Inventory
        coalesce(stock_quantity, 0) as stock_quantity,
        coalesce(reorder_level, 0)  as reorder_level,
 
        -- Metadata
        last_modified_date,
        _loaded_at

    from flattened_table
),
 
calculated_metrics as (
    select
        *,
        case
            when unit_price > 0 then ((unit_price - cost_price) / unit_price) * 100 
            else 0.00
        end as profit_margin_percentage,
 
        case
            when stock_quantity < reorder_level then true
            else false
        end as is_low_stock
    from cleaned_and_cast
)

select *
from calculated_metrics
qualify row_number() over (
    partition by product_id
    order by _loaded_at desc
) = 1
 