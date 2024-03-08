from datetime import timedelta, datetime
from airflow import DAG
from airflow.operators.python import PythonOperator

from ecommerce.models.user import User
from ecommerce.models.role_user import RoleUser
from ecommerce.models.address import Address


def user_info(num_users=1):
    instance = User()
    instance.generate_fake_users(num_users=num_users)


def user_address():
    instance = Address()
    instance.generate_addresses()


def assign_role():
    instance = RoleUser()
    instance.assign_roles_to_users()


# def insert_role():
#     instance = Role()
#     instance.generate_roles()


default_args = {
    'owner': 'airflow',
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5)
}

with DAG('ecommerce_user_registration',
         start_date=datetime(2023, 12, 1),
         schedule_interval='* * * * *',
         default_args=default_args, catchup=False) as dag:

    # insert_role_to_db = PythonOperator(
    #     task_id='insert_role_to_db',
    #     python_callable=insert_role
    # )

    generate_user_info = PythonOperator(
        task_id='generate_user_info',
        python_callable=user_info,
        op_args=[2]
    )

    assign_role_to_user = PythonOperator(
        task_id='assign_role_to_user',
        python_callable=assign_role
    )

    generate_user_address = PythonOperator(
        task_id='generate_user_address',
        python_callable=user_address
    )

# insert_role_to_db >> generate_user_info >> assign_role_to_user >> generate_user_address

generate_user_info >> assign_role_to_user >> generate_user_address
