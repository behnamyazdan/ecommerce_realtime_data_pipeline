import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config


class OrderStatus(object):
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_order_statuses(self):
        try:
            statuses = [
                "Pending",
                "Processing",
                "Shipped",
                "Delivered",
                "Cancelled"
            ]

            status_data = [(status,) for status in statuses]

            query = "INSERT INTO orderstatus (order_status_name) VALUES %s"
            execute_values(self.cur, query, status_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating order statuses: {e}")


def main():
    order_status_model_generator = OrderStatus()
    order_status_model_generator.generate_order_statuses()


if __name__ == "__main__":
    main()
