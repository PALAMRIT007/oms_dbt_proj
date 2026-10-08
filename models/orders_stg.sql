{{
    config(materialized='incremental',
    unique_key = 'orderid')
}}

select orderid, 
orderdate, 
customerid, 
employeeid, 
storeid, 
status as statuscd,
case 
    when status = '01' then 'In Progress'
    when status = '02' then 'Completed'
    when status = '03' then 'Cancelled'
    else NULL
end as statusdesc,
case
    when storeid = 1000 then 'online'
    else 'In-store'
    end as order_channel,
updated_at,
current_timestamp as dbt_updated_at
from {{source('landing','orders')}}

{% if is_incremental() %}
where updated_at >= (select max(updated_at) from {{this}})
{%endif%}

