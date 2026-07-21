with flattened_table as (
    select
        --Store Details
        sto_json:store_id::varchar             as store_id,
        sto_json:store_name::varchar           as store_name,
        sto_json:store_type::varchar           as store_type,
        sto_json:region::varchar               as region,       
        coalesce(sto_json:size_sq_ft::integer, 0) as size_sq_ft,
        sto_json:opening_date::varchar         as opening_date,
       
        -- Store Address
        sto_json:address:street::varchar       as street,
        sto_json:address:city::varchar         as city,
        sto_json:address:state::varchar        as state,
        sto_json:address:zip_code::varchar     as zip_code,
        sto_json:address:country::varchar      as country,
        
        -- Store contanct & Management
        sto_json:email::varchar                as email,
        sto_json:phone_number::varchar         as phone,
        sto_json:manager_id::varchar           as manager_id,
        sto_json:is_active::boolean            as is_active,
 
        -- Measures
        coalesce(sto_json:current_sales::decimal(18,2), 0.00) as current_sales,
        coalesce(sto_json:sales_target::decimal(18,2), 0.00)  as sales_target,
        coalesce(sto_json:employee_count::integer, 0)         as employee_count,
        sto_json:monthly_rent::varchar                        as rent,
       
        -- Metadata
        dbt_valid_from as valid_from,
        coalesce(
            dbt_valid_to,
            '9999-12-31'::timestamp
        ) as valid_to,
        case
            when dbt_valid_to is null then true
            else false
        end as is_current,
        _loaded_at
    from {{ ref('Store_snap') }}
    where store_id is not null
),
 
cleaned_and_cast as (
    select
        store_id,
       
        -- Attribute
        coalesce(replace(initcap(trim(store_name)), ' ', ''), 'NA') as store_name,
        case
            when upper(trim(store_type)) = 'STANDARD'  then 'Standard'
            when upper(trim(store_type)) = 'FRANCHISE' then 'Franchise'
            when upper(trim(store_type)) = 'OUTLET'    then 'Outlet'
            else 'NA'
        end as store_type,
        coalesce(upper(trim(region)), 'NA')        as region,
        coalesce(upper(trim(manager_id)), 'NA') as manager_id,
        coalesce(is_active, false)                           as is_active,
        {{ standardize_date('opening_date')}} as opening_date,
        {{ clean_email('email') }} as email_cleaned,
        {{ clean_phone('phone') }} as phone_cleaned,

        -- Measure
        coalesce(initcap(trim(size_sq_ft)), 'NA')size_sq_ft,
        employee_count,
        current_sales,
        sales_target,
        {{ clean_currency('rent') }} as monthly_rent_usd,
 
        -- Store years & Size
        case
            when YEAR({{ standardize_date('opening_date') }}) = 1900 THEN -1
            else DATEDIFF(
                year,
                {{ standardize_date('opening_date') }},
                CURRENT_DATE()
            ) - 1
        end as store_age_years,
        case
            when size_sq_ft < 5000 then 'Small'
            when size_sq_ft >= 5000 and size_sq_ft <= 10000 then 'Medium'
            when size_sq_ft > 10000 then 'Large'
            else 'Unknown'
        end as store_size_category,
 
        -- Address
        coalesce(initcap(trim(street)), 'Unknown Street') as street,
        coalesce(initcap(trim(city)), 'Unknown City')     as city,
        coalesce(upper(trim(state)), 'NA')                as state,
        coalesce(trim(zip_code), '00000')                 as zip_code,
        coalesce(upper(trim(country)), 'UNKNOWN')         as country,
        concat_ws(', ', 
            initcap(trim(street)), 
            initcap(trim(city)), 
            upper(trim(state)), 
            trim(zip_code), 
            upper(trim(country))) 
        as standardized_full_address,
        case
            when trim(zip_code) rlike '^[0-9]{5}(-[0-9]{4})?$' then true
            else false
        end as is_postal_code_valid,
 
        -- Metadata
        valid_from,
        valid_to,
        is_current,
        _loaded_at
    from flattened_table
),
 
calculated_performance as (
    select
        *,
        coalesce(
            case
                when sales_target > 0 then cast((current_sales / sales_target) * 100 as decimal(18, 2))
                else 0.00
            end,
            0.00
        ) as sales_target_achievement_percentage,
 
        coalesce(
            case
                when size_sq_ft > 0 then cast(current_sales / size_sq_ft as decimal(18, 2))
                else 0.00
            end,
            0.00
        ) as revenue_per_sq_ft,
 
        coalesce(
            case
                when employee_count > 0 then cast(current_sales / employee_count as decimal(18, 2))
                else 0.00
            end,
            0.00
        ) as employee_efficiency
    from cleaned_and_cast
),
 
final_flags as (
    select
        *,
        case
            when sales_target_achievement_percentage < 90.00 then true
            else false
        end as has_performance_issue
    from calculated_performance
)

select *
from final_flags
qualify row_number() over (
    partition by store_id
    order by _loaded_at desc
) = 1
 

 