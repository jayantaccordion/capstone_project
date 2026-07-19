{% macro full_name(first_name_col, last_name_col) %}
    coalesce(
        nullif(
            concat_ws(
                ' ',
                initcap(nullif(trim({{ first_name_col }}), '')),
                initcap(nullif(trim({{ last_name_col }}), ''))
            ),
            ''
        ),
        'Unknown'
    )
{% endmacro %}