-- Transactions Table and Materialized View ------------------------------
USE default;
CREATE TABLE IF NOT EXISTS transactions
(
    order_id UInt32,
    transaction_type LowCardinality(String),
    amount Decimal(15, 2) Codec(LZ4),
    status LowCardinality(String),
    created_at Datetime64(3),
    ttl DateTime DEFAULT now()
)
ENGINE MergeTree
PARTITION BY toYYYYMMDD(created_at)
ORDER BY (created_at, transaction_type)
TTL ttl + INTERVAL 7 DAY;

CREATE TABLE IF NOT EXISTS _kafka_transactions
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.transactions',
    kafka_group_name = 'clickhouse_transaction_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_transactions to transactions
(
    order_id String,
    transaction_type String,
    amount String,
    status String,
    created_at String
) AS SELECT
    JSONExtractString(message, 'after.order_id') AS order_id,
    JSONExtractString(message, 'after.transaction_type') AS transaction_type,
    JSONExtractString(message, 'after.amount') AS amount,
    JSONExtractString(message, 'after.status') AS status,
    JSONExtractString(message, 'after.created_at') AS created_at
FROM _kafka_transactions
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Orders Table and Materialized View ---------------------------------
CREATE TABLE IF NOT EXISTS orders
(
    id UInt32,
    user_id UInt32,
    staff_id UInt32,
    address_id UInt32,
    order_amount Decimal(15,2),
    discount_amount Decimal(15,2),
    tax_amount Decimal(15,2),
    total_amount Decimal(15,2),
    discount_id Nullable(UInt32),
    payment_method_id Nullable(UInt32),
    payment_status_id Nullable(UInt32),
    order_status_id UInt32,
    shipping_method_id Nullable(UInt32),
    shipping_status_id Nullable(UInt32),
    created_at Datetime64(3),
    ttl DateTime DEFAULT now()
)
ENGINE MergeTree
PARTITION BY toYYYYMMDD(created_at)
ORDER BY (id, user_id)
TTL ttl + INTERVAL 7 DAY;

CREATE TABLE IF NOT EXISTS _kafka_orders
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.orders',
    kafka_group_name = 'clickhouse_order_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_orders to orders
(
    id String,
    user_id String,
    staff_id String,
    address_id String,
    order_amount String,
    discount_amount String,
    tax_amount String,
    total_amount String,
    discount_id Nullable(String),
    payment_method_id Nullable(String),
    payment_status_id Nullable(String),
    order_status_id String,
    shipping_method_id Nullable(String),
    shipping_status_id Nullable(String),
    created_at Datetime64(3)
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.user_id') AS user_id,
    JSONExtractString(message, 'after.staff_id') AS staff_id,
    JSONExtractString(message, 'after.address_id') AS address_id,
    JSONExtractString(message, 'after.order_amount') AS order_amount,
    JSONExtractString(message, 'after.discount_amount') AS discount_amount,
    JSONExtractString(message, 'after.tax_amount') AS tax_amount,
    JSONExtractString(message, 'after.total_amount') AS total_amount,
    JSONExtractString(message, 'after.discount_id') AS discount_id,
    JSONExtractString(message, 'after.payment_method_id') AS payment_method_id,
    JSONExtractString(message, 'after.payment_status_id') AS payment_status_id,
    JSONExtractString(message, 'after.order_status_id') AS order_status_id,
    JSONExtractString(message, 'after.shipping_method_id') AS shipping_method_id,
    JSONExtractString(message, 'after.shipping_status_id') AS shipping_status_id,
    JSONExtractString(message, 'after.created_at') AS created_at
FROM _kafka_orders
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Products table ---------------------------------------------

CREATE TABLE IF NOT EXISTS products
(
	id UInt32,
	product_name String,
	category_id UInt32,
	brand_id UInt32,
	product_price Float32
)
ENGINE MergeTree
ORDER BY  (id, category_id, brand_id);

CREATE TABLE IF NOT EXISTS _kafka_products
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.products',
    kafka_group_name = 'clickhouse_products_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_products TO products
(
    id UInt32,
    product_name String,
    category_id UInt32,
    brand_id UInt32,
    product_price Float32  -- Adjust the data type based on your requirements
) AS SELECT
    toUInt32(JSONExtractString(message, 'after.id')) AS id,
    JSONExtractString(message, 'after.product_name') AS product_name,
    toUInt32(JSONExtractString(message, 'after.category_id')) AS category_id,
    toUInt32(JSONExtractString(message, 'after.brand_id')) AS brand_id,
    toFloat32(JSONExtractString(message, 'after.product_price')) AS product_price
FROM _kafka_products
SETTINGS stream_like_engine_allow_direct_select = 1;


-- Tags table ------------------------------------------

CREATE TABLE IF NOT EXISTS tags
(
    id UInt32,
    tag_name String
) ENGINE = MergeTree
ORDER BY (id);

CREATE TABLE IF NOT EXISTS _kafka_tags
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.tags',
    kafka_group_name = 'clickhouse_tags_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_tags to tags
(
    id String,
    tag_name String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.tag_name') AS tag_name
FROM _kafka_tags
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Brands table ---------------------------------------------------

CREATE TABLE IF NOT EXISTS brands
(
    id UInt32,
    brand_name String
) ENGINE = MergeTree
ORDER BY (id);


CREATE TABLE IF NOT EXISTS _kafka_brands
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.brands',
    kafka_group_name = 'clickhouse_brands_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;


CREATE MATERIALIZED VIEW IF NOT EXISTS mv_brands to brands
(
    id String,
    brand_name String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.brand_name') AS brand_name
FROM _kafka_brands
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Users table -------------------------------------------------------

CREATE TABLE IF NOT EXISTS users
(
    id UInt32,
    username String,
    created_at Datetime64(3),
    ttl DATETIME DEFAULT now()
) ENGINE = MergeTree
ORDER BY (id);

CREATE TABLE IF NOT EXISTS _kafka_users
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.users',
    kafka_group_name = 'clickhouse_users_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_users to users
(
    id String,
    username String,
    created_at String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.username') AS username,
    JSONExtractString(message, 'after.created_at') AS created_at
FROM _kafka_users
SETTINGS stream_like_engine_allow_direct_select = 1;


-- roles table ------------------------------------------------

CREATE TABLE IF NOT EXISTS roles
(
    id UInt32,
    role_name String
) ENGINE = MergeTree
ORDER BY (id, role_name);

CREATE TABLE IF NOT EXISTS _kafka_roles
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.roles',
    kafka_group_name = 'clickhouse_roles_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_roles to roles
(
    id String,
    role_name String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.role_name') AS role_name
FROM _kafka_roles
SETTINGS stream_like_engine_allow_direct_select = 1;

-- role_user table ----------------------------------------------

CREATE TABLE IF NOT EXISTS role_user
(
    id UInt32,
    role_id UInt32,
    user_id UInt32
) ENGINE = MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS _kafka_role_user
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.role_user',
    kafka_group_name = 'clickhouse_role_user_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_role_user to role_user
(
    id String,
    role_id String,
    user_id String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.role_id') AS role_id,
    JSONExtractString(message, 'after.user_id') AS user_id
FROM _kafka_role_user
SETTINGS stream_like_engine_allow_direct_select = 1;

-- provinces table --------------------------------------------

CREATE TABLE IF NOT EXISTS provinces
(
    id UInt32,
    province_name LowCardinality(String)
) ENGINE = MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192; -- Optional, adjust based on your needs

CREATE TABLE IF NOT EXISTS _kafka_provinces
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.provinces',
    kafka_group_name = 'clickhouse_provinces_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_provinces to provinces
(
    id String,
    province_name String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.province_name') AS province_name
FROM _kafka_provinces
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Cities table -------------------------------------------------

CREATE TABLE IF NOT EXISTS cities
(
    id UInt32,
    city_name LowCardinality(String),
    province_id UInt32,
    latitude Float32,
    longitude Float32
) ENGINE = MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS _kafka_cities
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.cities',
    kafka_group_name = 'clickhouse_cities_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_cities to cities
(
    id String,
    city_name String,
    province_id String,
    latitude String,
    longitude String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.city_name') AS city_name,
    JSONExtractString(message, 'after.province_id') AS province_id,
    JSONExtractString(message, 'after.latitude') AS latitude,
    JSONExtractString(message, 'after.longitude') AS longitude
FROM _kafka_cities
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Addresses table ---------------------------------------------

CREATE TABLE IF NOT EXISTS addresses
(
    id UInt32,
    title LowCardinality(String),
    user_id UInt32,
    province_id UInt32,
    city_id UInt32
) ENGINE = MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192; -- Optional, adjust based on your needs

CREATE TABLE IF NOT EXISTS _kafka_addresses
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.addresses',
    kafka_group_name = 'clickhouse_addresses_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_addresses to addresses
(
    id String,
    title String,
    user_id String,
    province_id String,
    city_id String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.title') AS title,
    JSONExtractString(message, 'after.user_id') AS user_id,
    JSONExtractString(message, 'after.province_id') AS province_id,
    JSONExtractString(message, 'after.city_id') AS city_id
FROM _kafka_addresses
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Categories Table ---------------------------------------------

CREATE TABLE IF NOT EXISTS categories
(
    id UInt32,
    category_name LowCardinality(String),
    category_id Nullable(UInt32)
) ENGINE = MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS _kafka_categories
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.categories',
    kafka_group_name = 'clickhouse_categories_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_categories to categories
(
    id String,
    category_name String,
    category_id String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.category_name') AS category_name,
    JSONExtractString(message, 'after.category_id') AS category_id
FROM _kafka_categories
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Product_Tag Table -------------------------------------
CREATE TABLE IF NOT EXISTS product_tag
(
    product_id UInt32,
    tag_id UInt32
) ENGINE = MergeTree
ORDER BY (tag_id, product_id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS _kafka_product_tag
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.product_tag',
    kafka_group_name = 'clickhouse_product_tag_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_product_tag to product_tag
(
    product_id String,
    tag_id String
) AS SELECT
    JSONExtractString(message, 'after.product_id') AS product_id,
    JSONExtractString(message, 'after.tag_id') AS tag_id
FROM _kafka_product_tag
SETTINGS stream_like_engine_allow_direct_select = 1;

-- AdsCampaign Table ----------------------------------

CREATE TABLE IF NOT EXISTS adscampaigns
(
    id UInt32,
    campaign_title LowCardinality(String)
) ENGINE = MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS _kafka_adscampaign
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.adscampaigns',
    kafka_group_name = 'clickhouse_product_adscampaigns_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_adscampaigns to adscampaigns
(
    id String,
    campaign_title String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.campaign_title') AS campaign_title
FROM _kafka_adscampaign
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Discounts Table -------------------------------------------------

CREATE TABLE IF NOT EXISTS discounts
(
    id UInt32,
    adscampaign_id Nullable(UInt32),
    type LowCardinality(String),
    value String,
    code String,
    started_at Datetime64(3),
    expired_at Datetime64(3)
) ENGINE = MergeTree
ORDER BY (id, started_at)
SETTINGS index_granularity = 8192; -- Optional, adjust based on your needs

CREATE TABLE IF NOT EXISTS _kafka_discounts
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.discounts',
    kafka_group_name = 'clickhouse_discounts_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_discounts to discounts
(
    id String,
    adscampaign_id String,
    type String,
    value String,
    code String,
    started_at Datetime64(3),
    expired_at Datetime64(3)
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.adscampaign_id') AS adscampaign_id,
    JSONExtractString(message, 'after.type') AS type,
    JSONExtractString(message, 'after.value') AS value,
    JSONExtractString(message, 'after.code') AS code,
    JSONExtractString(message, 'after.started_at') AS started_at,
    JSONExtractString(message, 'after.expired_at') AS expired_at
FROM _kafka_discounts
SETTINGS stream_like_engine_allow_direct_select = 1;

-- OrderStatus Table -------------------------------------------

CREATE TABLE IF NOT EXISTS orderstatus
(
	id UInt32,
	order_status_name String
) ENGINE MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS _kafka_orderstatus
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.orderstatus',
    kafka_group_name = 'clickhouse_orderstatus_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_orderstatus to orderstatus
(
    id String,
    order_status_name String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.order_status_name') AS order_status_name
FROM _kafka_orderstatus
SETTINGS stream_like_engine_allow_direct_select = 1;

-- PaymentMethods Table -------------------------------------------

CREATE TABLE IF NOT EXISTS paymentmethods
(
	id UInt32,
	payment_method_name String
) ENGINE MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS _kafka_paymentmethods
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.paymentmethods',
    kafka_group_name = 'clickhouse_paymentmethods_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_paymentmethods to paymentmethods
(
    id String,
    payment_method_name String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.payment_method_name') AS payment_method_name
FROM _kafka_paymentmethods
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Payment Status Table-------------------------------------

CREATE TABLE IF NOT EXISTS paymentstatus
(
	id UInt32,
	payment_status_name String
) ENGINE MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS _kafka_paymentstatus
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.paymentstatus',
    kafka_group_name = 'clickhouse_paymentstatus_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_paymentstatus to paymentstatus
(
    id String,
    payment_status_name String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.payment_status_name') AS payment_status_name
FROM _kafka_paymentstatus
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Shipping Status Table-------------------------------------

CREATE TABLE IF NOT EXISTS shippingstatus
(
	id UInt32,
	shipping_status_name String
) ENGINE MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS _kafka_shippingstatus
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.shippingstatus',
    kafka_group_name = 'clickhouse_shippingstatus_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_shippingstatus to shippingstatus
(
    id String,
    shipping_status_name String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.shipping_status_name') AS shipping_status_name
FROM _kafka_shippingstatus
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Shipping Methods Table-------------------------------------
CREATE TABLE IF NOT EXISTS shippingmethods
(
	id UInt32,
	shipping_method_name String
) ENGINE MergeTree
ORDER BY (id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS _kafka_shippingmethods
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.shippingmethods',
    kafka_group_name = 'clickhouse_shippingmethods_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_shippingmethods to shippingmethods
(
    id String,
    shipping_method_name String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.shipping_method_name') AS shipping_method_name
FROM _kafka_shippingmethods
SETTINGS stream_like_engine_allow_direct_select = 1;

-- OrderDetails Table-------------------------------------
CREATE TABLE IF NOT EXISTS orderdetails
(
    id UInt32,
    order_id UInt32,
    product_id UInt32,
    quantity Int32,
    product_price Decimal(15, 2),
    product_tax Decimal(15, 2),
    subtotal_amount Decimal(15, 2),
    created_at Datetime64(3) DEFAULT now()
) ENGINE = MergeTree
PARTITION BY (toYYYYMM(created_at))
ORDER BY (order_id, product_id)
SETTINGS index_granularity = 8192; -- Optional, adjust based on your needs

CREATE TABLE IF NOT EXISTS _kafka_orderdetails
(
    `message` String
)
ENGINE Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker:19092',
    kafka_topic_list = 'ecommerce_cdc.public.orderdetails',
    kafka_group_name = 'clickhouse_orderdetails_consumer',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1,
    kafka_max_block_size = 1048576;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_orderdetails to orderdetails
(
    id String,
    order_id String,
    product_id String,
    quantity String,
    product_price String,
    product_tax String,
    subtotal_amount String
) AS SELECT
    JSONExtractString(message, 'after.id') AS id,
    JSONExtractString(message, 'after.order_id') AS order_id,
    JSONExtractString(message, 'after.product_id') AS product_id,
    JSONExtractString(message, 'after.quantity') AS quantity,
    JSONExtractString(message, 'after.product_price') AS product_price,
    JSONExtractString(message, 'after.product_tax') AS product_tax,
    JSONExtractString(message, 'after.subtotal_amount') AS subtotal_amount
FROM _kafka_orderdetails
SETTINGS stream_like_engine_allow_direct_select = 1;


------------ Analytical Tables ------------

-- Creates a table to store total revenue and quantity per product, using SummingMergeTree engine for efficient aggregation.
-- The table will be sorted by product ID and name for optimized retrieval.
CREATE TABLE IF NOT EXISTS _at_total_revenue_per_products
(
    p_id UInt32,
    p_name String,
    total_revenue Float32,
    total_qty UInt32
) ENGINE SummingMergeTree((total_revenue, total_qty))
ORDER BY (p_id, p_name);

-- Creates a materialized view to calculate total revenue and quantity per product.
-- It aggregates data from orders, orderdetails, and products tables, filtering by specific order statuses ('Processing', 'Shipped', 'Delivered').
-- The aggregated results are stored in the _at_total_revenue_per_products table.
-- Sets stream_like_engine_allow_direct_select to 1 to allow direct SELECT queries from the materialized view.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_total_revenue_per_products TO _at_total_revenue_per_products
(   p_id UInt32,
    p_name String,
    total_revenue Float32,
    total_qty UInt32
) AS
    SELECT
        products.id AS p_id,
        product_name AS p_name,
        orderdetails.quantity AS total_qty,
        orderdetails.subtotal_amount AS total_revenue
    FROM orders
    JOIN orderdetails ON orders.id = orderdetails.order_id
    JOIN products ON orderdetails.product_id = products.id
    JOIN orderstatus ON orders.order_status_id = orderstatus.id
    WHERE
        orders.order_status_id IN (SELECT id FROM orderstatus WHERE order_status_name IN ('Processing', 'Shipped', 'Delivered'))
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Creates a table to store monthly revenue totals.
-- Utilizes the AggregatingMergeTree engine for efficient storage and aggregation of monthly revenue data.
-- Data will be partitioned by month for optimized retrieval.
CREATE TABLE IF NOT EXISTS _at_monthly_orders_status
(
    month UInt32,
    monthly_revenue AggregateFunction(sum, Decimal(15,2)),
    avg_order_value AggregateFunction(avg, Decimal(15,2)),
    monthly_orders AggregateFunction(count, UInt32)
)
ENGINE = AggregatingMergeTree()
PARTITION BY month
ORDER BY (month);

select month, sumMerge(monthly_revenue), avgMerge(avg_order_value), countMerge(monthly_orders)  FROM _at_monthly_orders_status group by month;


-- Creates a materialized view to compute monthly revenue totals.
-- Aggregates data from the orders table, calculating total revenue for each month.
-- The results are stored in the _at_monthly_orders_status table.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_monthly_orders_status TO _at_monthly_orders_status
(
    month UInt32,
    monthly_revenue Decimal(15,2),
    avg_order_value Decimal(15,2),
    monthly_orders UInt32
)
AS
SELECT toYYYYMM(created_at) AS month,
       sumState(total_amount) AS monthly_revenue,
       avgState(total_amount) as avg_order_value,
       countState(id) as monthly_orders
FROM orders
WHERE order_status_id IN
      (SELECT id FROM orderstatus WHERE order_status_name IN ('Processing', 'Shipped', 'Delivered'))
GROUP BY month
SETTINGS stream_like_engine_allow_direct_select = 1;

-- Create a ClickHouse table to store daily user registration counts.
-- The table "_at_daily_user_registration" uses the SummingMergeTree engine for efficient aggregation of registration counts.
-- Data is partitioned by day to optimize query performance and storage efficiency.
-- The table schema consists of two columns: "day" (UInt32) for the month identifier and "registration" (UInt32) for the count of user registrations.
-- Monthly registration counts are aggregated using the "registration" column.
-- The table is ordered by month for faster retrieval of sequential data.
CREATE TABLE IF NOT EXISTS _at_daily_user_registration
(
    day UInt32,
    registration UInt32
)
ENGINE SummingMergeTree((registration))
PARTITION BY day
ORDER BY (day);

-- Create a materialized view to aggregate daily user registration counts.
-- The materialized view "_mv_at_daily_user_registration" aggregates data from the "users" table.
-- Data is grouped by day, and the number of registrations per day is calculated using the COUNT function.
-- The "toYYYYMMDD(created_at)" function is used to extract the year, month, and day from the registration date.
-- The aggregated data is stored in the "_at_user_registration_statistics" table.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_daily_user_registration TO _at_daily_user_registration
(
    day UInt32,
    registration UInt32
)
AS
SELECT toYYYYMMDD(created_at) AS day, COUNT(id) AS registrations
FROM users
GROUP BY day;

optimize table _at_daily_user_registration final;

-- Create a ClickHouse table to store monthly user registration counts.
-- The table "_at_monthly_user_registration" uses the SummingMergeTree engine for efficient aggregation of registration counts.
-- Data is partitioned by month to optimize query performance and storage efficiency.
-- The table schema consists of two columns: "month" (UInt32) for the month identifier and "registration" (UInt32) for the count of user registrations.
-- Monthly registration counts are aggregated using the "registration" column.
-- The table is ordered by month for faster retrieval of sequential data.
CREATE TABLE IF NOT EXISTS _at_monthly_user_registration
(
    month UInt32,
    registration UInt32
)
ENGINE SummingMergeTree((registration))
PARTITION BY month
ORDER BY (month);

-- Create a materialized view to aggregate monthly user registration counts.
-- The materialized view "_mv_at_daily_user_registration" aggregates data from the "users" table.
-- Data is grouped by month, and the number of registrations per month is calculated using the COUNT function.
-- The "toYYYYMM(created_at)" function is used to extract the year, and month from the registration date.
-- The aggregated data is stored in the "_at_user_registration_statistics" table.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_monthly_user_registration TO _at_monthly_user_registration
(
    month UInt32,
    registration UInt32
)
AS
SELECT toYYYYMMDD(created_at) AS month, COUNT(id) AS registrations
FROM users
GROUP BY month;



-- Create a ClickHouse table to store aggregate order counts by city and date.
-- The table "_at_city_orders_by_date" uses the AggregatingMergeTree engine for efficient aggregation of order counts.
-- Data is partitioned by month (toYYYYMM(date)) to optimize query performance and storage efficiency.
-- The table schema includes columns for city name ("city_name"), date ("date"), and the aggregate function "order_count" to compute the count of orders.
-- Orders are aggregated based on the combination of city and date.
-- The table is ordered by date for faster retrieval of sequential data.
CREATE TABLE IF NOT EXISTS _at_city_orders_by_date
(
    city_name String,
    date Date,
    order_count AggregateFunction(count, UInt32)
)
ENGINE AggregatingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, city_name);

-- Create a materialized view to aggregate order counts by city and date.
-- The materialized view "_mv_at_city_orders_by_date" aggregates data from the "orders" table.
-- Data is grouped by city name and date, and the count of orders per city and date is calculated using the countState function.
-- The aggregated data is stored in the "_at_city_orders_by_date" table.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_city_orders_by_date TO _at_city_orders_by_date
(
    city_name String,
    date Date,
    order_count UInt32
) AS
SELECT city_name,
       DATE(created_at) AS date,
       countState(orders.id) AS order_count
FROM orders
JOIN addresses ON orders.address_id = addresses.id
JOIN cities ON addresses.city_id = cities.id
GROUP BY city_name, date;



-- Create a ClickHouse table to store total sales and order counts per category.
-- The table "_at_total_sales_per_category" uses the AggregatingMergeTree engine for efficient aggregation of sales data.
-- Data is aggregated by category name, with aggregate functions "sum" and "count" used to calculate total sales and order counts respectively.
-- The table schema includes columns for category name ("category_name"), total sales ("total_sales"), and order count ("order_count").
-- The table is ordered by total sales and order count to optimize query performance.
CREATE TABLE IF NOT EXISTS _at_total_sales_per_category
(
    category_name String,
    total_sales AggregateFunction(sum, Decimal(15, 2)),
    order_count AggregateFunction(count, UInt32)
)
ENGINE AggregatingMergeTree()
ORDER BY tuple();

-- Create a materialized view to aggregate total sales and order counts per category.
-- The materialized view "_mv_at_total_sales_per_category" aggregates data from the "orderdetails" table.
-- Data is joined with the "products" and "categories" tables to retrieve category information.
-- The sumState function calculates the total sales (subtotal_amount) per category, while the countState function computes the order count per category.
-- The aggregated data is stored in the "_at_total_sales_per_category" table.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_total_sales_per_category TO _at_total_sales_per_category
(
    category_name String,
    total_sales Decimal(15, 2),
    order_count UInt32
) AS
SELECT category_name,
       sumState(subtotal_amount) AS total_sales,
       countState(orderdetails.id) AS order_count
FROM orderdetails
JOIN products ON orderdetails.product_id = products.id
JOIN categories ON products.category_id = categories.id
GROUP BY category_name
ORDER BY (total_sales, order_count) DESC;


-- Create a ClickHouse table to store total sales per user.
-- The table "_at_total_sales_per_user" uses the SummingMergeTree engine for efficient aggregation of total sales.
-- Data is aggregated by user ID, with the sum of total sales stored in the "total_amount" column.
-- The table is ordered by user ID for faster retrieval of sequential data.
CREATE TABLE IF NOT EXISTS _at_total_sales_per_user
(
    user_id UInt64,
    total_amount Decimal(15, 2)
)
ENGINE SummingMergeTree((total_amount))
ORDER BY total_amount;

-- Create a materialized view "_mv_at_total_sales_per_user" to aggregate total sales per user.
-- The view selects data from the "orders" table, extracting user IDs and total amounts.
-- Each user's total sales are computed by summing the total amounts from their respective orders.
-- The aggregated data is then stored in the "_at_total_sales_per_user" table for efficient querying and analysis.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_total_sales_per_user TO _at_total_sales_per_user
(
    user_id UInt64,
    total_amount Decimal(15, 2)
) AS
SELECT user_id, total_amount FROM orders;



-- Create a ClickHouse table to store the number of products in each brand.
-- The table "_at_number_of_products_in_each_brand" uses the AggregatingMergeTree engine for efficient aggregation.
-- Data is aggregated by brand name, with the count of products computed using the count aggregate function.
-- The table is ordered by brand name for faster retrieval and sequential access.
CREATE TABLE IF NOT EXISTS _at_number_of_products_in_each_brand
(
    brand_name String,
    product_count AggregateFunction(count, UInt32)
)
ENGINE AggregatingMergeTree()
ORDER BY (brand_name);

-- Create a materialized view to aggregate the number of products in each brand.
-- The view "_mv_at_number_of_products_in_each_brand" aggregates data from the "products" table.
-- Data is joined with the "brands" table to retrieve brand names.
-- The countState function calculates the number of products per brand.
-- The aggregated data is stored in the "_at_number_of_products_in_each_brand" table.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_number_of_products_in_each_brand TO _at_number_of_products_in_each_brand
(
    brand_name String,
    product_count UInt32
) AS
SELECT brand_name, countState(products.id) AS product_count
FROM products
JOIN brands ON products.brand_id = brands.id
GROUP BY brand_name;



-- Create a ClickHouse table to store the number of orders for each shipping method.
-- The table "_at_number_of_orders_for_each_shipping_method" uses the AggregatingMergeTree engine for efficient aggregation.
-- Data is aggregated by shipping method name, with the count of orders computed using the count aggregate function.
-- The table is ordered by shipping method name for faster retrieval and sequential access.
CREATE TABLE IF NOT EXISTS _at_number_of_orders_for_each_shipping_method
(
    shipping_method_name String,
    order_count AggregateFunction(count, UInt32)
)
ENGINE AggregatingMergeTree()
ORDER BY shipping_method_name;

-- Create a materialized view to aggregate the number of orders for each shipping method.
-- The view "_mv_at_number_of_orders_for_each_shipping_method" aggregates data from the "orders" table.
-- Data is joined with the "shippingmethods" table to retrieve shipping method names.
-- The countState function calculates the number of orders per shipping method.
-- The aggregated data is stored in the "_at_number_of_orders_for_each_shipping_method" table.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_number_of_orders_for_each_shipping_method TO _at_number_of_orders_for_each_shipping_method
(
    shipping_method_name String,
    order_count UInt32
)
AS
SELECT shipping_method_name, countState(id) AS order_count
FROM orders
JOIN shippingmethods ON orders.shipping_method_id = shippingmethods.id
GROUP BY shipping_method_name;



-- Create a ClickHouse table to store the number of orders for each payment method.
-- The table "_at_number_of_orders_for_each_payment_method" uses the AggregatingMergeTree engine for efficient aggregation.
-- Data is aggregated by payment method name, with the count of orders computed using the count aggregate function.
-- The table is ordered by payment method name for faster retrieval and sequential access.
CREATE TABLE IF NOT EXISTS _at_number_of_orders_for_each_payment_method
(
    payment_method_name String,
    order_count AggregateFunction(count, UInt32)
)
ENGINE AggregatingMergeTree()
ORDER BY payment_method_name;

-- Create a materialized view to aggregate the number of orders for each payment method.
-- The view "_mv_at_number_of_orders_for_each_payment_method" aggregates data from the "orders" table.
-- Data is joined with the "paymentmethods" table to retrieve payment method names.
-- The countState function calculates the number of orders per payment method.
-- The aggregated data is stored in the "_at_number_of_orders_for_each_payment_method" table.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_number_of_orders_for_each_payment_method TO _at_number_of_orders_for_each_payment_method
(
    payment_method_name String,
    order_count UInt32
)
AS
SELECT payment_method_name, countState(id) AS order_count
FROM orders
JOIN paymentmethods ON orders.shipping_method_id = paymentmethods.id
GROUP BY payment_method_name;



-- Create a ClickHouse table to store the number of users in each province.
-- The table "_at_number_of_users_in_each_province" uses the AggregatingMergeTree engine for efficient aggregation.
-- Data is aggregated by province name, with the count of users computed using the count aggregate function.
-- The table is ordered by province name for faster retrieval and sequential access.
CREATE TABLE IF NOT EXISTS _at_number_of_users_in_each_province
(
    province_name String,
    user_count AggregateFunction(count, UInt32)
)
ENGINE AggregatingMergeTree()
ORDER BY province_name;

-- Create a materialized view to aggregate the number of users in each province.
-- The view "_mv_at_number_of_users_in_each_province" aggregates data from the "users" table.
-- Data is joined with the "addresses" and "provinces" tables to retrieve province names.
-- The countState function calculates the number of users per province.
-- The aggregated data is stored in the "_at_number_of_users_in_each_province" table.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_number_of_users_in_each_province TO _at_number_of_users_in_each_province
(
    province_name String,
    user_count UInt32
) AS
SELECT province_name, countState(users.id) AS user_count
FROM users
JOIN addresses ON users.id = addresses.user_id
JOIN provinces ON addresses.province_id = provinces.id
GROUP BY province_name;


-- Create a ClickHouse table to store the total number of products sold by city.
-- The table "_at_total_number_of_products_sold_by_city" uses the SummingMergeTree engine for efficient aggregation.
-- Data is aggregated by city name, with the total number of products sold stored in the "total_sold" column.
-- The table is ordered by total number of products sold and then by city name for faster retrieval and sequential access.
CREATE TABLE IF NOT EXISTS _at_total_number_of_products_sold_by_city
(
    city_name String,
    total_sold UInt32
)
ENGINE SummingMergeTree((total_sold))
ORDER BY (total_sold, city_name);


-- Create a materialized view to aggregate the total number of products sold by city.
-- The view "_mv_at_total_number_of_products_sold_by_city" aggregates data from the "orderdetails" table.
-- Data is joined with the "orders", "addresses", and "cities" tables to retrieve city names.
-- The "quantity" column from the "orderdetails" table represents the number of products sold.
-- The aggregated data is stored in the "_at_total_number_of_products_sold_by_city" table.
CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_total_number_of_products_sold_by_city TO _at_total_number_of_products_sold_by_city
(
    city_name String,
    total_sold UInt32
) AS
SELECT city_name, quantity AS total_sold
FROM orderdetails
JOIN orders ON orderdetails.order_id = orders.id
JOIN addresses ON orders.address_id = addresses.id
JOIN cities ON addresses.city_id = cities.id;


-- Test Query ---------------------------------------------------

-- SELECT toDate(created_at) AS order_date, COUNT(id) AS order_count
-- FROM orders
-- GROUP BY order_date
-- ORDER BY order_date;

-- SELECT city_name, SUM(quantity) AS total_sold
-- FROM orderdetails
-- JOIN orders ON orderdetails.order_id = orders.id
-- JOIN addresses ON orders.address_id = addresses.id
-- JOIN cities ON addresses.city_id = cities.id
-- GROUP BY city_name;

-- SELECT province_name, countMerge(user_count) FROM _at_number_of_users_in_each_province GROUP BY province_name;

-- SELECT payment_method_name, COUNT(id) AS usage_count
-- FROM orders
-- JOIN paymentmethods ON orders.payment_method_id = paymentmethods.id
-- GROUP BY payment_method_name
-- ORDER BY usage_count DESC;

-- SELECT payment_method_name, countMerge(order_count) as order_count
-- FROM _at_number_of_orders_for_each_payment_method
-- GROUP BY payment_method_name
-- ORDER BY order_count DESC ;

-- SELECT shipping_method_name, countMerge(order_count) as order_count
-- FROM _at_number_of_orders_for_each_shipping_method
-- GROUP BY shipping_method_name
-- ORDER BY order_count DESC ;

-- SELECT brand_name, countMerge(product_count) FROM _at_number_of_products_in_each_brand GROUP BY brand_name;

-- SELECT brand_name, COUNT(products.id) AS product_count
-- FROM products
-- JOIN brands ON products.brand_id = brands.id
-- GROUP BY brand_name;

-- SELECT user_id, SUM(total_amount) AS total_spent
-- FROM orders
-- GROUP BY user_id
-- ORDER BY total_spent DESC;

-- SELECT category_name, SUM(subtotal_amount) AS total_sales, count(orderdetails.id) AS order_count
-- FROM orderdetails
-- JOIN products ON orderdetails.product_id = products.id
-- JOIN categories ON products.category_id = categories.id
-- GROUP BY category_name
-- ORDER BY (total_sales, order_count) DESC;

-- select count(id) from products where category_id = 588;

-- select id, category_name from categories where category_name = 'civil';

-- SELECT category_name, sumMerge(total_sales), countMerge(order_count) From _at_total_sales_per_category
-- GROUP BY category_name ORDER BY category_name DESC;


-- SELECT city_name, date,
--        countMerge(order_count)
-- FROM _at_city_orders_by_date
-- GROUP BY city_name, date;


-- SELECT city_name,
--        DATE(created_at) AS date,
--        count(orders.id) AS order_count
-- FROM orders
-- JOIN addresses ON orders.address_id = addresses.id
-- JOIN cities ON addresses.city_id = cities.id
-- GROUP BY city_name, date;

-- SELECT toYYYYMM(created_at) as month, sum(total_amount), avg(total_amount), count(id)
-- FROM orders
-- WHERE order_status_id IN
--       (SELECT id FROM orderstatus WHERE order_status_name IN ('Processing', 'Shipped', 'Delivered'))
-- GROUP BY month;
--
-- SELECT month, round(sumMerge(monthly_revenue), 2),  round(avgMerge(avg_order_value), 2), countMerge(monthly_orders) FROM _at_monthly_revenue GROUP BY month;
--
--
-- OPTIMIZE TABLE _at_monthly_revenue FINAL ;

-- select sum(orderdetails.subtotal_amount), sum(quantity) from orderdetails where product_id = 1213;
select * from _at_total_revenue_per_products order by total_qty DESC LIMIT 10;

-- SELECT toYYYYMM(created_at) AS month, SUM(total_amount) AS monthly_revenue
-- FROM orders
-- GROUP BY month
-- ORDER BY month;

-- SELECT toYYYYMM(created_at) AS month, SUM(total_amount) AS monthly_revenue
-- FROM orders
-- GROUP BY month
-- ORDER BY month;


-- Creates a table to store aggregated monthly order data.
-- Utilizes SummingMergeTree engine for efficient aggregation of total amount and total order count.
-- Data will be sorted by month for optimized retrieval.
-- CREATE TABLE IF NOT EXISTS _at_monthly_orders
-- (
--     month DATE,
--     total_amount Float32,
--     total_order UInt32
-- ) ENGINE SummingMergeTree((total_amount, total_order))
-- ORDER BY month;
--
-- -- Creates a materialized view to calculate monthly order totals.
-- -- Aggregates data from the orders table, computing total order amount and count for each month.
-- -- Filters orders by specific statuses ('Processing', 'Shipped', 'Delivered').
-- -- Results are stored in the _at_monthly_orders table.
-- -- Sets stream_like_engine_allow_direct_select to 1 to allow direct SELECT queries from the materialized view.
-- CREATE MATERIALIZED VIEW IF NOT EXISTS _mv_at_monthly_orders TO _at_monthly_orders
-- (
--     month DATE,
--     total_amount Float32,
--     total_order UInt32
-- ) AS
-- SELECT toYYYYMM(created_at) AS month, total_amount, 1 as total_order
-- FROM orders
-- WHERE order_status_id IN
--       (SELECT id FROM orderstatus WHERE order_status_name IN ('Processing', 'Shipped', 'Delivered'))
-- SETTINGS stream_like_engine_allow_direct_select = 1;