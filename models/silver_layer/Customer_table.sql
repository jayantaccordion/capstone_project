with flattened_table as(
    select
        cust_json:customer_id::varchar                as customer_id,

        -- Customer Personal Information
        cust_json:first_name::varchar                 as first_name,
        cust_json:last_name::varchar                  as last_name,
        cust_json:email::varchar                      as email,
        cust_json:phone::varchar                      as phone,
        cust_json:birth_date::varchar                 as birth_date,
        cust_json:last_modified_date::varchar         as last_modified_date,
        cust_json:registration_date::varchar          as reg_date,
        cust_json:last_purchase_date::varchar         as last_purchase_date,

        -- Customer Attributes
        cust_json:income_bracket::varchar             as income_bracket,
        cust_json:loyalty_tier::varchar               as loyalty_tier,
        cust_json:total_purchases::integer            as total_purchases,
        cust_json:total_spend::integer                as total_spend,
        cust_json:marketing_opt_in::boolean           as marketing_opt_in,
        cust_json:occupation::varchar                 as occupation,
        cust_json:preferred_payment_method::varchar   as preferred_payment_method,
        cust_json:preferred_communication::varchar    as preferred_communication,

        -- Customer Address
        cust_json:address.city::varchar               as city,
        cust_json:address.state::varchar              as state,
        cust_json:address.country::varchar            as country,
        cust_json:address.street::varchar             as street,
        cust_json:address.zip_code::varchar           as zip_code,

        -- Snapshot Metadata
        dbt_valid_from as valid_from,
        coalesce(
            dbt_valid_to,
            '9999-12-31'::timestamp
        ) as valid_to,
        case
            when dbt_valid_to is null then true
            else false
        end as is_current,
        _loaded_at,

    from {{ ref('Customer_snap') }}
    where customer_id is not null
),

cleaned_and_cast as (
    select
        customer_id,
       
        --Customer Name
        coalesce(initcap(trim(first_name)), 'Unknown') as first_name,
        coalesce(initcap(trim(last_name)), 'Unknown') as last_name,
        {{ full_name('first_name', 'last_name') }} as full_name,
       
       --Email Validation
        email as raw_email,
        {{ clean_email('email') }} as email,
        case
            when {{ clean_email('email') }} is not null
            then true
            else false
        end as is_email_valid,
 
        --Phone Validation
        phone as raw_phone,
        {{ clean_phone('raw_phone')}} as phone,
        case
            when {{ clean_email('phone') }} is not null
            then true
            else false
        end as is_phone_valid,
 
        -- Dates
        {{ standardize_date('reg_date') }}              as registration_date,
        {{ standardize_date('birth_date') }}            as birth_date,
        {{ standardize_date('last_modified_date') }}    as last_modified_date,
        {{ standardize_date('last_purchase_date') }}    as last_purchase_date,
 
        -- Customer Attributes
        coalesce(upper(trim(loyalty_tier)), 'STANDARD')             as loyalty_tier,
        coalesce(marketing_opt_in, false)                           as marketing_opt_in,
        coalesce(initcap(trim(occupation)),'Unknown')               as occupation,
        coalesce(initcap(trim(preferred_payment_method)),'Unknown') as preferred_payment_method,
        coalesce(initcap(trim(preferred_communication)),'Unknown')  as preferred_communication,
 
        -- Customer Address
        coalesce(initcap(trim(street)), 'Unknown Street') as street,
        coalesce(initcap(trim(city)), 'Unknown City')     as city,
        coalesce(upper(trim(state)), 'NA')                as state,
        coalesce(trim(zip_code), '00000')                 as zip_code,
        coalesce(upper(trim(country)), 'UNKNOWN')         as country,
 
        -- Customer Measure
        {{ clean_currency('total_spend') }} as total_spend_usd,
        coalesce(total_purchases, 0)        as total_purchases,
 
        -- Snapshot Metadata
        _loaded_at,
        valid_from,
        valid_to,
        is_current

    from flattened_table
),
segmented_data as (
    select
        *,
        CASE
            WHEN YEAR(birth_date) = 1900 THEN -1
            ELSE DATEDIFF(year, birth_date, CURRENT_DATE()) - 1
        END AS customer_age,
        case
            when YEAR({{ standardize_date('birth_date') }}) = 1900 then 'Unknown'
            when customer_age between 18 and 35 then 'Young'
            when customer_age between 36 and 55 then 'Middle-aged'
            when customer_age >= 56             then 'Senior'
            else 'Unknown'                  
        end as customer_segment
    from cleaned_and_cast
)
 
SELECT *
FROM segmented_data
qualify row_number() over (
    partition by customer_id
    order by _loaded_at desc
) = 1
