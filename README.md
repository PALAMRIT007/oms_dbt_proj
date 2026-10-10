# SleekMart OMS: dbt Project

A dbt project that transforms Order Management System (OMS) data in **Snowflake** into clean, tested staging and consumption tables. It covers incremental loading, deduplication, change history, source freshness checks, and data quality tests.

## Tech stack

- **dbt** (dbt Cloud for development and runs)
- **Snowflake** (database `SLEEKMART_OMS`)
- **Packages:** `dbt_utils`, `dbt_expectations`

## Data layers

| Layer | Schema | Purpose |
|---|---|---|
| Landing | `L1_LANDING` | Raw OMS data, loaded by ingestion (read-only for dbt) |
| Processing | `L2_PROCESSING` | Cleaned and deduplicated staging models |
| Consumption | `L3_CONSUMPTION` | Analytics-ready tables, including customer history |

## Sources

Defined in a single `sources.yml` under `models/`.

- **`landing`** (`SLEEKMART_OMS.L1_LANDING`): `customers`, `orders`, `orderitems`, `employees`, `stores`, `suppliers`, `products`, `sales_us`, `sales_europe`, `sales_asia`
- **`training`** (`SLEEKMART_OMS.TRAINING`): `city_temperature`, `sales_us`, `sales_uk`, `sales_india`

Freshness is checked on the `landing` source using `updated_at` (warn after 1 day, error after 3 days).

## Models

| Model | Type | Description |
|---|---|---|
| `customer_stg` | Staging | Cleaned customers from `landing.customers` |
| `orders_stg` | Incremental (merge) | Orders with a decoded status (`01` In Progress, `02` Completed, `03` Cancelled), an `order_channel` flag (`online` when `storeid = 1000`, otherwise `In-store`), and a `dbt_updated_at` load timestamp |
| `orderitems_uniq` | Staging | Order items deduplicated to the latest version per record |
| `CUSTOMERS_HISTORY` | History | Tracks customer changes over time in `L3_CONSUMPTION` |

### Incremental pattern (`orders_stg`)

```sql
{{ config(materialized='incremental', unique_key='orderid') }}
...
{% if is_incremental() %}
where updated_at >= (select max(updated_at) from {{ this }})
{% endif %}
```

On Snowflake, dbt runs this as a `MERGE` on `orderid`: matching orders are updated in place and new orders are inserted. The filter compares `updated_at` to `updated_at`, the same column on both sides.

### Deduplication pattern

Snowflake supports `QUALIFY`, which keeps the latest row per key:

```sql
select *
from {{ source('landing', 'orderitems') }}
qualify row_number() over (partition by orderid order by updated_at desc) = 1
```

For adapters without `QUALIFY` (such as PostgreSQL), use `dbt_utils.deduplicate` or `DISTINCT ON`.

## Macros

- **`to_celsius(fahrenheit_column, decimal_place=1)`**: converts Fahrenheit to Celsius. Used with the `training.city_temperature` data.
- **`insert_test_orders()`**: inserts 10 test rows into `L1_LANDING.ORDERS` to exercise the incremental merge. Dev and test only.

```bash
dbt run-operation insert_test_orders
```

## Tests

- **Singular test** `tests/record_count_check.sql`: loops over the landing tables and fails for any table whose row count is below its expected minimum.
- **Generic tests:** `not_null` and `string_not_empty` on `employees.address`.
- **`dbt_expectations`:** `expect_table_row_count_to_equal_other_table`, comparing `orderitems_uniq` with `orders_stg`.

```bash
dbt test
dbt test --select record_count_check
```

## Getting started

```bash
# 1. Install packages
dbt deps

# 2. Check source freshness
dbt source freshness

# 3. Build and test everything
dbt build

# 4. Snapshots (customer history)
dbt snapshot
```

`packages.yml` must sit in the project root with exactly that name (with an **s**).

## Testing the incremental merge

1. Run the model once with `--full-refresh` to create the table.
2. Insert new rows or update existing rows in `L1_LANDING.ORDERS` (set `updated_at = current_timestamp`).
3. Run `dbt run --select orders_stg` without `--full-refresh`.
4. Open the run's debug logs and search for `merge into` to see the `when matched` and `when not matched` branches.

Remove test rows afterwards. An incremental run never deletes rows from staging, so delete them from both `L1_LANDING.ORDERS` and `L2_PROCESSING.orders_stg`.

## Lessons learned

- The second argument of `source()` must match the table `name:` in the YAML, not the physical table name.
- Source names must be unique across the project. Two YAML files declaring `landing` cause a duplicate error.
- `identifier:` is the valid key in a source table, not `identifiers:`.
- Config keys in `dbt_project.yml` need the `+` prefix (`+materialized`, `+schema`), and the model names under `models:` must match real models or dbt warns about unused config paths.
- `target/compiled/` holds only the `select`. The `merge` or `create table` statement appears in `target/run/` and in the debug logs.
- `is_incremental()` is false on the first run and on `--full-refresh`, so the filter only appears on normal incremental runs.
- A singular test in `tests/` runs automatically and passes when it returns zero rows. It is not referenced from YAML.
- Config files with fixed names (`dbt_project.yml`, `packages.yml`, `profiles.yml`, `selectors.yml`) must be named exactly. YAML files under `models/` can have any name.
- A `{{ config(schema=...) }}` or `+schema` setting decides which schema a model builds in. A model that lands in your dev schema instead of `L2_PROCESSING` usually points to a config mismatch.

## Project structure

```
oms_dbt_proj/
├── dbt_project.yml
├── packages.yml
├── models/          # staging models and sources.yml
├── macros/          # to_celsius, insert_test_orders
├── snapshots/       # customer history
├── tests/           # record_count_check.sql
├── seeds/
└── analyses/
```
