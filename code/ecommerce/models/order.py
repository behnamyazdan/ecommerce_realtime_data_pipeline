import psycopg2
import random
from datetime import datetime
from psycopg2.extras import execute_values
from decimal import Decimal
from ecommerce.config.database import db_config


class OrderRegistration(object):

    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def fetch_random_user_by_role(self, role_name):
        self.cur.execute("SELECT id FROM users WHERE id IN (SELECT user_id FROM role_user WHERE role_id IN (SELECT id "
                         "FROM roles WHERE role_name = %s)) ORDER BY RANDOM() DESC LIMIT 1", (role_name,))
        result = self.cur.fetchone()
        return result[0] if result else None

    def fetch_user_address(self, user_id):
        self.cur.execute("SELECT id FROM addresses WHERE user_id = %s", (user_id,))
        result = self.cur.fetchone()
        return result[0] if result else None

    def fetch_random_available_products(self):
        num_of_product = random.randint(1, 10)
        self.cur.execute("SELECT id, product_price, product_tax, product_quantity FROM products "
                         "WHERE product_quantity > 0 ORDER BY "
                         "RANDOM() LIMIT %s", (num_of_product,))
        return self.cur.fetchall()

    def fetch_order_status_item(self, status_name='Pending'):
        self.cur.execute("SELECT * FROM orderstatus WHERE order_status_name=%s LIMIT 1", (status_name,))
        result = self.cur.fetchone()
        return result[0] if result else None

    def fetch_random_order_status_item(self):
        self.cur.execute("SELECT * FROM orderstatus ORDER BY RANDOM() LIMIT 1")
        result = self.cur.fetchone()
        return result[0] if result else None

    def change_order_status(self, order_id, status_name):
        self.cur.execute("SELECT id FROM orderstatus WHERE order_status_name=%s LIMIT 1", (status_name,))
        result = self.cur.fetchone()
        status_id = result[0] if result else None

        if status_id:
            self.cur.execute("""
                UPDATE orders SET order_status_id = %s WHERE id = %s
            """, (status_id, order_id))
            self.conn.commit()
        else:
            return None

    def fetch_random_shipping_method(self):
        self.cur.execute("SELECT id FROM shippingmethods ORDER BY RANDOM() DESC LIMIT 1")
        result = self.cur.fetchone()
        return result[0] if result else None

    def fetch_random_payment_method(self):
        self.cur.execute("SELECT id FROM paymentmethods ORDER BY RANDOM() DESC LIMIT 1")
        result = self.cur.fetchone()
        return result[0] if result else None

    def fetch_order_discount(self):
        self.cur.execute("SELECT id, type, value FROM discounts WHERE expired_at > %s ORDER BY RANDOM() DESC LIMIT 1",
                         (datetime.now(),))
        return self.cur.fetchone()

    def calculate_order_amount(self, products):
        return sum(item[5] for item in products)

    def prepare_order_details_item(self, product):
        for index, item in enumerate(product):
            product_id = item[0]
            order_quantity = max(1, int(item[3] * 0.1))
            product_price = item[1]
            product_tax = item[2]
            product_price_after_tax = product_price * (product_tax / Decimal('100'))
            subtotal_amount = Decimal(product_price_after_tax * order_quantity)

            product[index] = (product_id, order_quantity, product_price, product_tax, subtotal_amount)
        return product

    def save_order(self):

        # for _ in range(num_order):
        order_customer_id = self.fetch_random_user_by_role('customer')
        order_address_id = self.fetch_user_address(order_customer_id)

        print("----------------------------")
        print(order_address_id)
        print("----------------------------")


        if order_customer_id and order_address_id:

            order_staff_id = self.fetch_random_user_by_role('staff')
            order_status_id = self.fetch_order_status_item()
            order_products = self.fetch_random_available_products()
            prepared_order_items = self.prepare_order_details_item(order_products)
            order_amount = sum(item[1] * item[2] for item in prepared_order_items)
            tax_amount = sum(item[2] * (item[3] / Decimal('100')) for item in prepared_order_items)

            if random.randint(0, 10) > 6:
                order_discount = self.fetch_order_discount()
                discount_id = order_discount[0]
                if order_discount[1] == 'percent':
                    discount_amount = order_amount * (order_discount[2] / Decimal('100'))
                else:
                    discount_amount = order_amount - order_discount[2]
            else:
                discount_id = None
                discount_amount = 0

            total_amount = (order_amount + tax_amount) - discount_amount
            order_payment_method = self.fetch_random_payment_method()
            order_shipping_method = self.fetch_random_shipping_method()

            order_data = (
                order_customer_id, order_staff_id, order_address_id, order_amount, discount_amount, tax_amount,
                total_amount,
                discount_id, order_payment_method, None, order_status_id, order_shipping_method, None)

            try:

                self.cur.execute("BEGIN;")

                insert_order_query = """
                    INSERT INTO orders (user_id, staff_id, address_id, order_amount, discount_amount, tax_amount,
                                        total_amount, discount_id, payment_method_id, payment_status_id, order_status_id,
                                        shipping_method_id, shipping_status_id)
                    VALUES %s RETURNING id
                """
                execute_values(self.cur, insert_order_query, [order_data])
                order_id = self.cur.fetchone()[0] if self.cur.rowcount > 0 else None

                # print([order_data])
                print(order_products)

                order_detail_data = [(order_id, *item) for item in prepared_order_items]
                insert_order_details_query = """
                    INSERT INTO orderdetails (order_id, product_id, quantity, product_price, product_tax, subtotal_amount)
                    VALUES %s
                    """
                execute_values(self.cur, insert_order_details_query, order_detail_data)

                print(order_detail_data)

                self.conn.commit()
                print("Simulation completed successfully!")
                return order_id

            except Exception as e:
                self.conn.rollback()
                print(f"Error occurred: {e}")
                return None
        else:
            return None


def main():
    order_registration_model = OrderRegistration()
    order_registration_model.save_order()


if __name__ == "__main__":
    main()
