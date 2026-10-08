select * 
from {{ ref('orders_fact')}} ofact
where  ofact.revenue<0