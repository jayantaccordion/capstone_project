with date_spine as (
    {{
        dbt_utils.date_spine(
            datepart="day",
            start_date="'1900-01-01'",
            end_date="'2030-12-31'"
        )
    }}
)
 
select
    cast(to_char(date_day, 'YYYYMMDD') as number) as date_key,
    date_day as full_date,

    year(date_day) as year,
    quarter(date_day) as quarter,

    month(date_day) as month_number,
    monthname(date_day) as month_name,
 
    week(date_day) as week_number,
    dayofweek(date_day) as day_of_week_number,
    dayname(date_day) as day_of_week_name,
 
    day(date_day) as day_of_month,
 
    case
        when dayofweek(date_day) in (0,6) then true
        else false
    end as is_weekend,

    case
        when month(date_day) in (12,1,2) then 'Winter'
        when month(date_day) in (3,4,5) then 'Spring'
        when month(date_day) in (6,7,8) then 'Summer'
        else 'Fall'
    end as season
    
from date_spine
 