import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config
from faker import Faker
import random
import re


class Category:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_unique_slug(self, category_name, existing_slugs):
        # Generate a unique slug based on the category name
        slug = re.sub(r'\W+', '-', category_name.lower())
        base_slug = slug
        counter = 1

        while slug in existing_slugs:
            slug = f"{base_slug}-{counter}"
            counter += 1

        return slug

    def get_valid_category_ids(self):
        # Fetch existing product category IDs from the table
        self.cur.execute("SELECT id FROM categories WHERE category_name ILIKE 'Product%'")  # Assuming product categories start with 'Product'
        return [row[0] for row in self.cur.fetchall()]

    def generate_fake_categories(self, num_categories):
        fake = Faker()
        try:
            existing_slugs = set()
            self.cur.execute("SELECT slug FROM categories")
            existing_slugs.update(row[0] for row in self.cur.fetchall())

            valid_category_ids = self.get_valid_category_ids()

            category_data = []
            for _ in range(num_categories):
                category_name = fake.word()
                slug = self.generate_unique_slug(category_name, existing_slugs)

                if valid_category_ids:
                    parent_category_id = random.choice([None] + valid_category_ids)  # Choose None or a valid product category ID
                else:
                    parent_category_id = None

                category_data.append((category_name, slug, parent_category_id))
                existing_slugs.add(slug)

            query = "INSERT INTO categories (category_name, slug, category_id) VALUES %s"
            execute_values(self.cur, query, category_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating categories: {e}")


def main():
    category_model_generator = Category()
    category_model_generator.generate_fake_categories(num_categories=20)


if __name__ == "__main__":
    main()
