with flattened_table as(
    select
        cust.value:customer_id::string                as customer_id,
        cust.value:first_name::string                 as first_name,
        cust.value:last_name::string                  as last_name,
        cust.value:email::string                      as email,
        cust.value:phone::string                      as phone,
        cust.value:birth_date::string                 as birth_date,
        cust.value:last_modified_date::string         as last_modified_date,
        cust.value:registration_date::varchar         as reg_date,
        cust.value:last_purchase_date::string         as last_purchase_date,
        cust.value:income_bracket::string             as income_bracket,
        cust.value:loyalty_tier::string               as loyalty_tier,
        cust.value:total_purchases::integer           as total_purchases,
        cust.value:total_spend::integer               as total_spend,
        cust.value:marketing_opt_in::boolean          as marketing_opt_in,
        cust.value:occupation::string                 as occupation,
        cust.value:preferred_payment_method::string   as preferred_payment_method,
        cust.value:preferred_communication::string    as preferred_communication,

        cust.value:address.city::string               as city,
        cust.value:address.state::string              as state,
        cust.value:address.country::string            as country,
        cust.value:address.street::string             as street,
        cust.value:address.zip_code::string           as zip_code,

        _loaded_at
    from {{ ref('Customers_data') }},
    lateral flatten(input => raw_json_payload:customers_data) cust
    where customer_id is not null
),

cleaned_and_cast as (
    select
        customer_id,
       
        -- Trim whitespace + Standardize capitalization
        coalesce(initcap(trim(first_name)), 'Unknown') as first_name,
        coalesce(initcap(trim(last_name)), 'Unknown') as last_name,
       
        -- Create a full_name column
        concat(
            coalesce(initcap(trim(first_name)), 'Unknown'),
            ' ',
            coalesce(initcap(trim(last_name)), 'Unknown')
        ) as full_name,
       
        -- Validate and clean Email_Id, flagging and falling back for invalid values
        email as raw_email,
        {{ clean_email('email') }} as email_cleaned,
        case
            when {{ clean_email('email') }} rlike 'unknown@email.com' then false
            else true
        end 
        as is_email_valid,
 
        -- Validate and clean Phn_No, flagging and falling back for invalid values
        phone as raw_phone,
        coalesce(
            regexp_replace(phone, '[^0-9]', ''),
            '0000000000') as phone_cleaned,
        case
            when length(regexp_replace(phone, '[^0-9]', '')) >= 10 then true
            else false
        end    
        as is_phone_valid,
 
        -- Dates
        {{ standardize_date('reg_date') }}        as registration_date,
        {{ standardize_date('birth_date') }}      as birth_date,

        -- Calculate customer age from birth_date, falling back to -1 if birth_date is null
        CASE
            WHEN YEAR({{ standardize_date('birth_date') }}) = 1900 THEN -1
            ELSE DATEDIFF(
                year,
                {{ standardize_date('birth_date') }},
                CURRENT_DATE()
            ) - 1
        END AS customer_age,
 
        -- Categorical mapping defaults
        coalesce(upper(trim(loyalty_tier)), 'STANDARD') as loyalty_tier,
 
        -- Standardize address format with defaults
        coalesce(initcap(trim(street)), 'Unknown Street') as street,
        coalesce(initcap(trim(city)), 'Unknown City')     as city,
        coalesce(upper(trim(state)), 'NA')                as state,
        coalesce(trim(zip_code), '00000')                 as zip_code,
        coalesce(upper(trim(country)), 'UNKNOWN')         as country,
        coalesce(total_purchases, 0)                          as total_purchases,
 
        -- Currency parsing rule with fallback
        {{ clean_currency('total_spend') }} as total_spend_usd,
 
        coalesce(marketing_opt_in, false) as marketing_opt_in,
        _loaded_at
    from flattened_table
),
segmented_data as (
    select
        *,
        case
            when YEAR({{ standardize_date('birth_date') }}) = 1900 then 'Unknown'
            when customer_age between 18 and 35 then 'Young'
            when customer_age between 36 and 55 then 'Middle-aged'
            when customer_age >= 56             then 'Senior'
            else 'Unknown'                  
        end as customer_segment
    from cleaned_and_cast
)
 
-- Final Deduplication based on the natural key (customer_id)
SELECT *
FROM segmented_data
