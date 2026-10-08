select 
orderitemid,
orderid,
productid,
quantity,
unitprice,
quantity * unitprice as totalprice,
updated_at
from L1_LANDING.ORDERITEMS