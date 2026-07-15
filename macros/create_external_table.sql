{% macro create_external_table(table_name, data_source) %}
{% set sql %}
    USE DATABASE CT_JAYANT_PANDEY_DB;
    USE SCHEMA AZURE_RAW;
    create or replace external table {{ table_name }}
        WITH LOCATION = @CT_JAYANT_PANDEY_DB.AZURE_RAW.BLOB_STAGE/Capstone_Project_Data/{{ data_source }}
        FILE_FORMAT = (TYPE = JSON);
{% endset %}
{% do run_query(sql) %}
{% endmacro %}