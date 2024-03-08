CREATE TABLE IF NOT EXISTS users
(
    id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username varchar(100) NOT NULL unique,
    password varchar(255),
	email varchar(255) NOT NULL unique,
	mobile varchar(255) NOT NULL UNIQUE,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS roles
(
    id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	role_name varchar(50) NOT NULL UNIQUE,
	role_title varchar(50) NOT NULL,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(role_name, role_title)
);


CREATE TABLE IF NOT EXISTS role_user
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	role_id integer NOT NULL,
	user_id integer NOT NULL,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	
	UNIQUE(role_id, user_id),
	FOREIGN KEY (user_id) REFERENCES users(id),
	FOREIGN KEY (role_id) REFERENCES roles(id)
);


CREATE TABLE IF NOT EXISTS provinces
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	province_name varchar(100) NOT NULL UNIQUE,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cities
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	city_name varchar(100) NOT NULL,
	province_id integer NOT NULL,
    latitude numeric,
    longitude numeric,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(city_name, province_id),
	FOREIGN KEY (province_id) REFERENCES provinces(id)
);

CREATE TABLE IF NOT EXISTS addresses
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	title varchar(100) NOT NULL,
	user_id integer NOT NULL,
	province_id integer NOT NULL,
	city_id integer NOT NULL,
	full_address varchar(255),
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	
	FOREIGN KEY (user_id) REFERENCES users(id),
	FOREIGN KEY (province_id) REFERENCES provinces(id),
	FOREIGN KEY (city_id) REFERENCES cities(id)
);

CREATE TABLE IF NOT EXISTS categories
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	category_name varchar(100) NOT NULL,
	category_id integer, -- to create parent/childe relationship (self-join)
	slug varchar(100) NOT NULL UNIQUE,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	
	FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE IF NOT EXISTS brands
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	brand_name varchar(100) NOT NULL UNIQUE,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tags
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	tag_name varchar(100) NOT NULL UNIQUE,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	product_name varchar(255) NOT NULL,
	category_id integer NOT NULL,
	brand_id integer NOT NULL,
	product_description text,
	product_price NUMERIC(15,2) NOT NULL,
	product_tax numeric(4,2) NOT NULL DEFAULT 0,
	product_quantity integer NOT NULL DEFAULT 0,
	product_image_path varchar,
	created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	
	FOREIGN KEY (category_id) REFERENCES categories(id), 
	FOREIGN KEY (brand_id) REFERENCES brands(id)
);

CREATE TABLE IF NOT EXISTS product_tag
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	product_id integer NOT NULL,
	tag_id integer NOT NULL,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	
	UNIQUE(product_id, tag_id),
	FOREIGN KEY (product_id) REFERENCES products(id), 
	FOREIGN KEY (tag_id) REFERENCES tags(id)
);

CREATE TABLE IF NOT EXISTS adscampaigns
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	campaign_title varchar(255),
	started_at timestamp,
	expired_at timestamp,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE discount_type AS ENUM ('percent', 'amount');
CREATE TABLE IF NOT EXISTS discounts
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	adscampaign_id integer,
	type discount_type DEFAULT 'percent',
	value numeric(15,2), -- discount rate or discount amount
	code varchar(100) UNIQUE,
	started_at timestamp(0),
	expired_at timestamp(0),
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (adscampaign_id) REFERENCES adscampaigns(id)
);

-- ALTER TABLE discounts ADD CONSTRAINT fk_discounts_adscampaigns FOREIGN KEY (adscampaign_id) REFERENCES adscampaigns(id);


CREATE TABLE IF NOT EXISTS orderstatus
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	order_status_name varchar(100) NOT NULL UNIQUE,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS paymentmethods
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	payment_method_name varchar(100) NOT NULL UNIQUE,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS paymentstatus
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	payment_status_name varchar(100) NOT NULL UNIQUE,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shippingstatus
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	shipping_status_name varchar(100) NOT NULL UNIQUE,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shippingmethods
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	shipping_method_name varchar(100) NOT NULL UNIQUE,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	user_id integer NOT NULL,
	staff_id integer NOT NULL, -- The user ID of the order registerer 
	address_id integer NOT NULL,
	order_amount decimal(15,2) NOT NULL, -- Order amount without calculating tax and discount
	discount_amount decimal(15,2) NOT NULL,
	tax_amount decimal(15,2) NOT NULL,
	total_amount decimal(15,2) NOT NULL, -- Order amount after subtraction of discount and tax
	discount_id integer,
	payment_method_id integer,
	payment_status_id integer,
	order_status_id integer NOT NULL,
	shipping_method_id integer,
	shipping_status_id integer,
	shipped_at timestamp(0),
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	
	FOREIGN KEY (user_id) REFERENCES users(id),
	FOREIGN KEY (staff_id) REFERENCES users(id),
	FOREIGN KEY (discount_id) REFERENCES discounts(id),
	FOREIGN KEY (address_id) REFERENCES addresses(id),
	FOREIGN KEY (order_status_id) REFERENCES orderstatus(id),
	FOREIGN KEY (payment_method_id) REFERENCES paymentmethods(id),
	FOREIGN KEY (payment_status_id) REFERENCES paymentstatus(id),
	FOREIGN KEY (shipping_method_id) REFERENCES shippingmethods(id),
	FOREIGN KEY (shipping_status_id) REFERENCES shippingstatus(id)
);

CREATE TABLE IF NOT EXISTS order_status_history
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	order_id integer NOT NULL,
	order_status_id integer NOT NULL,
	staff_id integer NOT NULL,
	comments varchar(500),
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	
	UNIQUE(order_id, order_status_id),	
	FOREIGN KEY (order_id) REFERENCES orders(id),
	FOREIGN KEY (staff_id) REFERENCES users(id),
	FOREIGN KEY (order_status_id) REFERENCES orderstatus(id)
);

CREATE TABLE IF NOT EXISTS orderdetails
(
	id integer NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	order_id integer NOT NULL,
	product_id integer NOT NULL,
	quantity integer NOT NULL DEFAULT 1,
	product_price numeric(15, 2) NOT NULL,
	product_tax numeric(15, 2) NOT NULL,
	subtotal_amount numeric(15, 2) NOT NULL,
	created_at timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	
	FOREIGN KEY (order_id) REFERENCES orders(id),
	FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TYPE transaction_type AS ENUM ('payment', 'refund', 'adjustment', 'other');

CREATE TABLE transactions(
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    transaction_type transaction_type,
    amount NUMERIC(15, 2),
    status BOOLEAN DEFAULT FALSE,
    created_at timestamp(0) DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- ALTER TABLE transactions ADD COLUMN status BOOLEAN DEFAULT FALSE;

---------------------------------------
-->     Initialize Base Tables      <--
---------------------------------------

-- insert default value for 'ShippingStatus' table
INSERT INTO roles (role_name, role_title) VALUES ('admin', 'Administrator') ON CONFLICT DO NOTHING;
INSERT INTO roles (role_name, role_title) VALUES ('staff', 'Staff') ON CONFLICT DO NOTHING;
INSERT INTO roles (role_name, role_title) VALUES ('manager', 'Manager') ON CONFLICT DO NOTHING;
INSERT INTO roles (role_name, role_title) VALUES ('customer', 'Customer') ON CONFLICT DO NOTHING;

-- insert default value for 'ShippingStatus' table
INSERT INTO shippingstatus (shipping_status_name) VALUES ('Pending') ON CONFLICT DO NOTHING;
INSERT INTO shippingstatus (shipping_status_name) VALUES ('In Transit') ON CONFLICT DO NOTHING;
INSERT INTO shippingstatus (shipping_status_name) VALUES ('Out for Delivery') ON CONFLICT DO NOTHING;
INSERT INTO shippingstatus (shipping_status_name) VALUES ('Delivered') ON CONFLICT DO NOTHING;
INSERT INTO shippingstatus (shipping_status_name) VALUES ('Failed Attempt') ON CONFLICT DO NOTHING;
INSERT INTO shippingstatus (shipping_status_name) VALUES ('Returned') ON CONFLICT DO NOTHING;

-- insert default value for 'ShippingMethods' table
INSERT INTO shippingmethods (shipping_method_name) VALUES ('Standard Shipping') ON CONFLICT DO NOTHING;
INSERT INTO shippingmethods (shipping_method_name) VALUES ('Express Shipping') ON CONFLICT DO NOTHING;
INSERT INTO shippingmethods (shipping_method_name) VALUES ('Next-Day Delivery') ON CONFLICT DO NOTHING;
INSERT INTO shippingmethods (shipping_method_name) VALUES ('Free Shipping') ON CONFLICT DO NOTHING;
INSERT INTO shippingmethods (shipping_method_name) VALUES ('Pickup from Store') ON CONFLICT DO NOTHING;

-- insert default value for 'orderStatus' table
INSERT INTO orderstatus (order_status_name) VALUES ('Pending') ON CONFLICT DO NOTHING;
INSERT INTO orderstatus (order_status_name) VALUES ('Processing') ON CONFLICT DO NOTHING;
INSERT INTO orderstatus (order_status_name) VALUES ('Shipped') ON CONFLICT DO NOTHING;
INSERT INTO orderstatus (order_status_name) VALUES ('Delivered') ON CONFLICT DO NOTHING;
INSERT INTO orderstatus (order_status_name) VALUES ('Cancelled') ON CONFLICT DO NOTHING;

-- insert default value for 'PaymentStatus' table
INSERT INTO paymentstatus (payment_status_name) VALUES ('Pending') ON CONFLICT DO NOTHING;
INSERT INTO paymentstatus (payment_status_name) VALUES ('Authorized') ON CONFLICT DO NOTHING;
INSERT INTO paymentstatus (payment_status_name) VALUES ('Completed') ON CONFLICT DO NOTHING;
INSERT INTO paymentstatus (payment_status_name) VALUES ('Failed') ON CONFLICT DO NOTHING;
INSERT INTO paymentstatus (payment_status_name) VALUES ('Refunded') ON CONFLICT DO NOTHING;

-- insert default value for 'PaymentMethods' table
INSERT INTO paymentmethods (payment_method_name) VALUES ('Credit Card') ON CONFLICT DO NOTHING;
INSERT INTO paymentmethods (payment_method_name) VALUES ('Debit Card') ON CONFLICT DO NOTHING;
INSERT INTO paymentmethods (payment_method_name) VALUES ('PayPal') ON CONFLICT DO NOTHING;
INSERT INTO paymentmethods (payment_method_name) VALUES ('Bank Transfer') ON CONFLICT DO NOTHING;
INSERT INTO paymentmethods (payment_method_name) VALUES ('Cash on Delivery') ON CONFLICT DO NOTHING;
