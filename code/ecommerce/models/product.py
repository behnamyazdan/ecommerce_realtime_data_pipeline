import psycopg2
from psycopg2.extras import execute_values
from faker import Faker
import random

from ecommerce.config.database import db_config


class Product:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def get_category_ids(self):
        # Fetch existing category IDs from the table
        self.cur.execute("SELECT id FROM categories")
        return [row[0] for row in self.cur.fetchall()]

    def get_brand_ids(self):
        # Fetch existing brand IDs from the table
        self.cur.execute("SELECT id FROM brands")
        return [row[0] for row in self.cur.fetchall()]

    def generate_fake_products(self, num_products=20):
        fake = Faker()
        try:
            category_ids = self.get_category_ids()
            brand_ids = self.get_brand_ids()

            product_data = []
            for _ in range(num_products):
                product_name = fake.word()
                category_id = random.choice(category_ids)
                brand_id = random.choice(brand_ids)
                product_description = fake.text()
                product_price = round(random.uniform(10.0, 1000.0), 2)
                product_tax = round(random.uniform(0.0, 20.0), 2)
                product_quantity = random.randint(1, 100)
                product_image_path = fake.image_url()

                product_data.append((
                    product_name, category_id, brand_id, product_description,
                    product_price, product_tax, product_quantity, product_image_path
                ))

            query = """INSERT INTO products 
                       (product_name, category_id, brand_id, product_description,
                       product_price, product_tax, product_quantity, product_image_path)
                       VALUES %s"""
            execute_values(self.cur, query, product_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating products: {e}")


def main():
    product_model_generator = Product()
    product_model_generator.generate_fake_products()


if __name__ == "__main__":
    main()