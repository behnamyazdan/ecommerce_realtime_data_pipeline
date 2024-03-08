import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config
import random


class ProductTag:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_product_tag_associations(self, num_associations):
        try:
            # Fetch all product and tag IDs from respective tables
            self.cur.execute("SELECT id FROM products")
            product_ids = [row[0] for row in self.cur.fetchall()]

            self.cur.execute("SELECT id FROM tags")
            tag_ids = [row[0] for row in self.cur.fetchall()]

            product_tag_data = []
            for _ in range(num_associations):
                product_id = random.choice(product_ids)
                tag_id = random.choice(tag_ids)

                # Check the number of tags associated with the current product
                self.cur.execute(
                    "SELECT COUNT(*) FROM product_tag WHERE product_id = %s",
                    (product_id,)
                )
                tag_count = self.cur.fetchone()[0]

                if tag_count < 5:
                    product_tag_data.append((product_id, tag_id))

            # Insert unique combinations of product_id and tag_id
            insert_query = """
                INSERT INTO product_tag (product_id, tag_id)
                VALUES %s
                ON CONFLICT (product_id, tag_id) DO NOTHING
            """
            execute_values(self.cur, insert_query, product_tag_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating product-tag associations: {e}")


def main():
    product_tag_model_generator = ProductTag()
    product_tag_model_generator.generate_product_tag_associations(500)


if __name__ == "__main__":
    main()
