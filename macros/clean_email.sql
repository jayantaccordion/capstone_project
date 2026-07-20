{% macro clean_email(column_name) %}
    case
        when email rlike '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
        then lower(trim(email))
        else null
    end
{% endmacro %}