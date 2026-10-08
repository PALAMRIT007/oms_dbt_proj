{% macro insert_test_orders() %}

    {% set insert_sql %}
        insert into SLEEKMART_OMS.L1_LANDING.ORDERS
            (ORDERID, ORDERDATE, CUSTOMERID, EMPLOYEEID, STOREID, STATUS, UPDATED_AT)
        values
            (800481, current_date, 25663, 503292, 1000, '02', current_timestamp),
            (800213, current_date, 21717, 501367, 1000, '02', current_timestamp),
            (800054, current_date, 25236, 509267, 1000, '02', current_timestamp),
            (800961, current_date, 28803, 508120, 1000, '02', current_timestamp),
            (800908, current_date, 22372, 508195, 1000, '02', current_timestamp),
            (800886, current_date, 27967, 500567, 1000, '02', current_timestamp),
            (800651, current_date, 25925, 506890, 1000, '02', current_timestamp),
            (800124, current_date, 27891, 506609, 1000, '02', current_timestamp),
            (800712, current_date, 21561, 504956, 1000, '02', current_timestamp),
            (800526, current_date, 29841, 503102, 1000, '02', current_timestamp)
    {% endset %}

    {% do run_query(insert_sql) %}
    {% do adapter.commit() %}
    {{ log("Inserted 10 test rows into SLEEKMART_OMS.L1_LANDING.ORDERS", info=True) }}

{% endmacro %}