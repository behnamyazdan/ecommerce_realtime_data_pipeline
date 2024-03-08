from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

from ecommerce.models.product import Product
from ecommerce.models.product_tag import ProductTag
from airflow.models import DagRun
from airflow.exceptions import AirflowException


def check_if_brand_generated_success():
    dag_run = DagRun.find(dag_id='ecommerce_generate_brand', state='success')
    success = len(dag_run) > 0
    if not success:
        raise AirflowException("Brand generator DAG run was not successful.")


def check_if_category_generated_success():
    dag_run = DagRun.find(dag_id='ecommerce_generate_category', state='success')
    success = len(dag_run) > 0
    if not success:
        raise AirflowException("Category generator DAG run was not successful.")


def generate_product_data(num_product):
    product = Product()
    product.generate_fake_products(num_product)


def generate_tag_product(num_tag):
    product_tag = ProductTag()
    product_tag.generate_product_tag_associations(num_tag)


default_args = {
    'owner': 'airflow',
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 5,
    'retry_delay': timedelta(minutes=2)
}

with DAG('ecommerce_generate_product',
         start_date=datetime(2023, 12, 1),
         schedule_interval='@weekly',
         default_args=default_args, catchup=False) as dag:

    check_brand_generator_success = PythonOperator(
        task_id='check_brand_generator_success',
        python_callable=check_if_brand_generated_success,
        trigger_rule='all_success',
    )

    check_category_generator_success = PythonOperator(
        task_id='check_category_generator_success',
        python_callable=check_if_category_generated_success,
        trigger_rule='all_success',
    )

    generate_product = PythonOperator(
        task_id='generate_product',
        python_callable=generate_product_data,
        op_args=[25],
        trigger_rule='all_success',
    )

    generate_tag_for_product = PythonOperator(
        task_id='generate_tag_for_product',
        python_callable=generate_tag_product,
        op_args=[100],
        trigger_rule='all_success',
    )

check_brand_generator_success >> check_category_generator_success >> generate_product >> generate_tag_for_product
