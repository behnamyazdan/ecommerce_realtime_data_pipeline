from faker import Faker
import psycopg2
from psycopg2.extras import execute_values
import hashlib
from ecommerce.config.database import db_config


class User(object):
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()
        self.fake = Faker()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_fake_users(self, num_users=1):
        try:
            user_data = []
            for _ in range(num_users):
                username = self.fake.user_name()
                password = hashlib.sha256(self.fake.password().encode('utf-8')).hexdigest()
                email = self.fake.email()
                mobile = self.fake.phone_number()
                created_at = self.fake.date_time_between(start_date='-1y', end_date='now')
                user_data.append((username, password, email, mobile, created_at))

            query = "INSERT INTO users (username, password, email, mobile, created_at) VALUES %s RETURNING id"
            execute_values(self.cur, query, user_data)
            self.conn.commit()

        except psycopg2.Error as e:
            self.conn.rollback()
            print(f"Error while generating users: {e}")


def main():
    user_model_generator = User()
    user_model_generator.generate_fake_users(10)


if __name__ == "__main__":
    main()
