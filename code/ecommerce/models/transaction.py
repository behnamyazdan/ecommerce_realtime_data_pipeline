import random

import psycopg2
from ecommerce.models.order import OrderRegistration
from ecommerce.config.database import db_config


class Transaction(object):
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def get_order_data(self, order_id):
        if order_id:
            self.cur.execute("SELECT id, total_amount FROM orders WHERE id = %s", (order_id,))
            order_id, amount = self.cur.fetchone()
            return order_id, amount

        return None, None

    def change_order_status_based_on_transaction_status(self, order_id, status):
        order = OrderRegistration()
        if status:  # if transaction success
            order_status_name = random.choice(['Processing', 'Shipped', 'Delivered'])
            order.change_order_status(order_id, order_status_name)
        else:  # if transaction failed
            order_status_name = random.choice(['Pending', 'Cancelled'])
            order.change_order_status(order_id, order_status_name)

    def generate_transaction(self, orderid):
        status = random.choice(['true', 'false'])
        order_id, amount = self.get_order_data(orderid)
        transaction_type = 'payment'
        description = f'Fake transaction description for order #{order_id}'

        self.cur.execute(
            "INSERT INTO transactions (order_id, transaction_type, amount, description, status)"
            "VALUES (%s, %s, %s, %s, %s) RETURNING id",
            (order_id, transaction_type, amount, description, status))

        transaction_id = self.cur.fetchone()[0] if self.cur.rowcount > 0 else None
        self.conn.commit()

        self.change_order_status_based_on_transaction_status(order_id, status)


def main():
    transaction = Transaction()
    transaction.generate_transaction(30)


if __name__ == '__main__':
    main()
