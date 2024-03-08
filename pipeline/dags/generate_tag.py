from datetime import timedelta, datetime
from airflow import DAG
from airflow.operators.python import PythonOperator

from ecommerce.models.tag import Tag


def generate_tag_data(num_brands=1):
    Instance = Tag()
    Instance.generate_tags(num_brands)


default_args = {
    'owner': 'airflow',
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(5)
}

with DAG(
    'ecommerce_generate_tag',
    start_date=datetime(2023, 12, 1),
    schedule_interval='@once',
    default_args=default_args, catchup=False
) as dag:

    generate_tag = PythonOperator(
        task_id='generate_tag',
        python_callable=generate_tag_data,
        op_args=[50]
    )

