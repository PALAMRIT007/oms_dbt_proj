select 
city_code,
city,
month,
avg_temp_fahrenheit,
-- round((avg_temp_fahrenheit-32)*5/9,1) 
{{to_celsius('avg_temp_fahrenheit')}}
as avg_temp_celsius
from SLEEKMART_OMS.TRAINING.city_temperature