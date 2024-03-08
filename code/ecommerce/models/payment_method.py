import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config


class PaymentMethods:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_payment_methods(self):
        try:
            methods = [
                "Credit Card",
                "Debit Card",
                "PayPal",
                "Bank Transfer",
                "Cash on Delivery"
            ]

            method_data = [(method,) for method in methods]

            query = "INSERT INTO paymentmethods (payment_method_name) VALUES %s"
            execute_values(self.cur, query, method_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating payment methods: {e}")


def main():
    payment_methods_model_generator = PaymentMethods()
    payment_methods_model_generator.generate_payment_methods()


if __name__ == "__main__":
    main()
