{% macro clean_currency(column_name) %}
    coalesce(
        try_cast(
            regexp_replace(
                trim({{ column_name }}),
                '[\\$,]',
                ''
            ) as decimal(18,2)
        ),
        0.00
    )
{% endmacro %}