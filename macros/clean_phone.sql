{% macro clean_phone(column_name) %}
    coalesce(
        case
            when length(regexp_replace(trim({{ column_name }}), '[^0-9]', '')) >= 10
            then regexp_replace(trim({{ column_name }}), '[^0-9]', '')
            else null
        end,
        '0000000000'
    )
{% endmacro %}