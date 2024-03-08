import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config


class ShippingStatus:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_shipping_statuses(self):
        try:
            statuses = [
                "Pending",
                "In Transit",
                "Out for Delivery",
                "Delivered",
                "Failed Attempt",
                "Returned"
            ]

            status_data = [(status,) for status in statuses]

            query = "INSERT INTO shippingstatus (shipping_status_name) VALUES %s"
            execute_values(self.cur, query, status_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating shipping statuses: {e}")


def main():
    shipping_status_model_generator = ShippingStatus()
    shipping_status_model_generator.generate_shipping_statuses()


if __name__ == "__main__":
    main()
