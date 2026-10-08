{% macro to_celsius(fahrenheit_column, decimal_place = 1) %}  
    ROUND(({{fahrenheit_column}} -32) *5/9,{{decimal_place}})
    {% endmacro %}


{% macro generate_profit_model(table_name)%}
select
sales_date,
sum(quantity_sold * unit_sell_price) as total_revenue,
sum(quantity_sold * unit_purchase_cost) as total_cost,
sum(quantity_sold * unit_sell_price)  - sum(quantity_sold * unit_purchase_cost) as total_profit,
from {{source('training', table_name)}}
group by sales_date
{% endmacro %}