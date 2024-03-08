import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config


class ShippingMethods:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_shipping_methods(self):
        try:
            methods = [
                "Standard Shipping",
                "Express Shipping",
                "Next-Day Delivery",
                "Free Shipping",
                "Pickup from Store"
            ]

            method_data = [(method,) for method in methods]

            query = "INSERT INTO shippingmethods (shipping_method_name) VALUES %s ON CONFLICT DO NOTHING"
            execute_values(self.cur, query, method_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating shipping methods: {e}")


def main():
    shipping_methods_model_generator = ShippingMethods()
    shipping_methods_model_generator.generate_shipping_methods()


if __name__ == "__main__":
    main()
