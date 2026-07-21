select
    {{ dbt_utils.generate_surrogate_key(['store_id']) }} as store_key,
    store_id,
    store_name,
    street,
    city,
    state,
    zip_code,
    country,
    region,
    store_type,
    opening_date,
    store_size_category,
    has_performance_issue,
    is_active,
    is_postal_code_valid,
    valid_from,
    valid_to,
    is_current

from {{ ref('Silver_store_table') }}