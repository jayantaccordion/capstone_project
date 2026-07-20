select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,
    customer_id,
    full_name,
    email,
    phone,
    street,
    city,
    state,
    zip_code,
    country,
    birth_date,
    customer_age,
    loyalty_tier,
    customer_segment,
    registration_date,
    valid_from,
    valid_to,
    is_current

from {{ ref('Silver_customer_table') }}