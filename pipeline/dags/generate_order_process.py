from datetime import datetime, timedelta

from airflow import AirflowException

from ecommerce.models.order import OrderRegistration
from ecommerce.models.transaction import Transaction

from airflow.decorators import dag, task


@dag(
    dag_id='ecommerce_generate_order_process',
    start_date=datetime(2023, 12, 1),
    schedule=timedelta(minutes=1),
    catchup=False,
)
def order_process():
    @task(retries=5, retry_delay=timedelta(minutes=5))
    def generate_order_process():
        order = OrderRegistration()
        order_id = order.save_order()
        print(order_id)
        if order_id:
            return order_id

        raise AirflowException('Order not found...')

    @task(retries=5, retry_delay=timedelta(minutes=5))
    def generate_transaction_for_order(order_id):
        transaction = Transaction()
        transaction.generate_transaction(order_id)

    generate_transaction_for_order(generate_order_process())


order_process()
