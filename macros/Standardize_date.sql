{% macro standardize_date(column_name) %}
COALESCE(
    TRY_CAST({{ column_name }} AS DATE),
    '1900-01-01'::DATE
)
{% endmacro %}