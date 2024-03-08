import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config
from faker import Faker


class Tag:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_tags(self, num_tags):
        fake = Faker()
        try:
            unique_tags = set()
            while len(unique_tags) < num_tags:
                unique_tags.add(fake.unique.word())

            tag_data = [(tag,) for tag in unique_tags]

            query = "INSERT INTO tags (tag_name) VALUES %s"
            execute_values(self.cur, query, tag_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating tags: {e}")


def main():
    tag_model_generator = Tag()
    tag_model_generator.generate_tags(50)


if __name__ == "__main__":
    main()
