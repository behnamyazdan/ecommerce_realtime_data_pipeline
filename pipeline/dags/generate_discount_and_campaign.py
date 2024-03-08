from datetime import timedelta, datetime

from airflow import DAG
from airflow.operators.python import PythonOperator

# import sys
# sys.path.insert(0, '/opt/airflow/code')
from ecommerce.models.discount import Discount
from ecommerce.models.ads_campaign import AdsCampaigns


def generate_ads_campaign_data(num_campaigns=1):
    Instance = AdsCampaigns()
    Instance.generate_ad_campaigns(num_campaigns)


def generate_discount_data(num_discount=1):
    Instance = Discount()
    Instance.generate_discounts(num_discount)


default_args = {
    'owner': 'airflow',
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5)
}

with DAG(
    'ecommerce_generate_discount_and_campaign',
    start_date=datetime(2023, 12, 1),
    schedule_interval='@weekly',
    default_args=default_args, catchup=False
) as dag:

    generate_campaign = PythonOperator(
        task_id='generate_campaign',
        python_callable=generate_ads_campaign_data,
        op_args=[5]
    )

    generate_discount = PythonOperator(
        task_id='generate_discount',
        python_callable=generate_discount_data,
        op_args=[5]
    )

generate_campaign >> generate_discount
