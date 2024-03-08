from datetime import timedelta, datetime
from airflow import DAG
from airflow.operators.python import PythonOperator

from ecommerce.models.category import Category


def generate_category_data(num_cats=1):
    Instance = Category()
    Instance.generate_fake_categories(num_cats)


default_args = {
    'owner': 'airflow',
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5)
}

with DAG(
    'ecommerce_generate_category',
    start_date=datetime(2023, 12, 1),
    schedule_interval='@weekly',
    default_args=default_args, catchup=False
) as dag:

    generate_category = PythonOperator(
        task_id='generate_category',
        python_callable=generate_category_data,
        op_args=[20]
    )

