{{config(materialized='view')}}


with customerorders as (
select c.customerid, concat(c.firstname,' ', c.lastname) as customername, count(o.orderid) as no_of_orders
from L1_LANDING.CUSTOMERS c
join L1_LANDING.ORDERS o 
on c.customerid = o.customerid
group by c.customerid, customername
order by no_of_orders
)

select * from customerorders