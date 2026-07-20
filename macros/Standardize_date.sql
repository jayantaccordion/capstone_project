{% macro standardize_date(column_name) %}

COALESCE(
    TRY_CAST({{ column_name }} AS DATE),
    NULL::Date
)

{% endmacro %}