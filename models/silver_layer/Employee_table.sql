with flattened_table as (
    select
        s.value:store_id::varchar             as store_id,
        s.value:store_name::varchar           as store_name,
        s.value:store_type::varchar           as store_type,
        s.value:region::varchar               as region,
       
        coalesce(s.value:size_sq_ft::integer, 0) as size_sq_ft,
        s.value:opening_date::varchar         as opening_date,
       
        s.value:address:street::varchar       as street,
        s.value:address:city::varchar         as city,
        s.value:address:state::varchar        as state,
        s.value:address:zip_code::varchar     as zip_code,
        s.value:address:country::varchar      as country,
       
        s.value:email::varchar                as email,
        s.value:phone_number::varchar         as phone,
        s.value:manager_id::varchar           as manager_id,
        s.value:is_active::boolean            as is_active,
 
        coalesce(s.value:current_sales::decimal(18,2), 0.00) as current_sales,
        coalesce(s.value:sales_target::decimal(18,2), 0.00)  as sales_target,
        coalesce(s.value:employee_count::integer, 0)         as employee_count,
        s.value:monthly_rent::varchar                        as rent,
       
        _loaded_at
    from {{ ref('Store_data') }},
    lateral flatten(input => raw_json_payload:stores_data) s
),
 
cleaned_and_cast as (
    select
        store_id,
       
        coalesce(replace(initcap(trim(store_name)), ' ', ''), 'UnknownStore') as store_name,
       
        coalesce(initcap(trim(store_type)), 'Standard') as store_type,
        coalesce(upper(trim(region)), 'UNKNOWN')        as region,
        coalesce(upper(trim(manager_id)), 'UNKNOWN_MGR') as manager_id,
        coalesce(is_active, false)                           as is_active,
 
        size_sq_ft,
        employee_count,
        current_sales,
        sales_target,
 
        {{ clean_currency('rent') }} as monthly_rent_usd,
 
        -- Date Handling with standard fallback
        coalesce(try_to_date(opening_date, 'YYYY-MM-DD'), '1970-01-01'::date) as opening_date,
 
        -- Calculating store age in years from opening_date to current date
        coalesce(
            datediff(year, try_to_date(opening_date, 'YYYY-MM-DD'), current_date()),
            -1) as store_age_years,
 
        -- Store size category from square footage
        case
            when size_sq_ft < 5000 then 'Small'
            when size_sq_ft >= 5000 and size_sq_ft <= 10000 then 'Medium'
            when size_sq_ft > 10000 then 'Large'
            else 'Unknown'
        end as store_size_category,
 
        -- Email & Phone Validation Flags
        {{ clean_email('email') }} as email_cleaned,
 
        {{ clean_phone('phone') }} as phone_cleaned,
 
        -- Standardize address format and validate postal codes
        coalesce(initcap(trim(street)), 'Unknown Street') as street,
        coalesce(initcap(trim(city)), 'Unknown City')     as city,
        coalesce(upper(trim(state)), 'NA')                as state,
        coalesce(trim(zip_code), '00000')                 as zip_code,
        coalesce(upper(trim(country)), 'UNKNOWN')         as country,
       
        -- Combined full address string pattern
        concat_ws(', ', initcap(trim(street)), initcap(trim(city)), upper(trim(state)), trim(zip_code), upper(trim(country))) as standardized_full_address,
       
        -- US Zip codes format chack to validate
        case
            when trim(zip_code) rlike '^[0-9]{5}(-[0-9]{4})?$' then true
            else false
        end as is_postal_code_valid,
 
        _loaded_at
    from flattened_table
    where store_id is not null
),
 
calculated_performance as (
    select
        *,
        -- Calculate store performance metrics
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
        -- Flag stores with performance issues (achievement < 90%)
        case
            when sales_target_achievement_percentage < 90.00 then true
            else false
        end as has_performance_issue
    from calculated_performance
)
 
-- Final Deduplication based on the natural key (store_id)
select *
from final_flags
qualify row_number() over (
    partition by store_id
    order by _loaded_at desc
) = 1
 