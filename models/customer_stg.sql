select 
customerid,
firstname, lastname, Email, Phone, Address, city, state, zipcode, updated_at, 
concat(firstname,' ',lastname) as customername
-- from L1_LANDING.CUSTOMERS
from {{ source('landing','customers')}}