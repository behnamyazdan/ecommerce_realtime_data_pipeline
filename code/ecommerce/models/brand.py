import psycopg2
from psycopg2.extras import execute_values
from faker import Faker
from ecommerce.config.database import db_config


class Brand(object):
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_fake_brands(self, num_brands=1):
        fake = Faker()
        try:
            brand_data = [(fake.company(),) for _ in range(num_brands)]
            query = "INSERT INTO brands (brand_name) VALUES %s"
            execute_values(self.cur, query, brand_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating brands: {e}")


def main():
    brand_model_generator = Brand()
    brand_model_generator.generate_fake_brands()


if __name__ == "__main__":
    main()
