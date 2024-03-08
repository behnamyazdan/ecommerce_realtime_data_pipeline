from datetime import timedelta, datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from ecommerce.models.brand import Brand


def generate_brand_data(num_brands=1):
    Instance = Brand()
    Instance.generate_fake_brands(num_brands)


default_args = {
    'owner': 'airflow',
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5)
}

with DAG(
    'ecommerce_generate_brand',
    start_date=datetime(2024, 1, 1),
    schedule_interval='@weekly',
    default_args=default_args, catchup=False
) as dag:

    generate_brand = PythonOperator(
        task_id='generate_brand',
        python_callable=generate_brand_data,
        op_args=[5]
    )

