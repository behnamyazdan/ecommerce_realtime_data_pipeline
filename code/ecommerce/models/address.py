import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config
from faker import Faker


class Address:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_addresses(self):
        fake = Faker()
        try:
            # Fetching user IDs from the users table where address doesn't exist
            self.cur.execute("SELECT id FROM users WHERE NOT EXISTS"
                             "(SELECT user_id FROM addresses WHERE user_id = users.id)")
            user_ids = [row[0] for row in self.cur.fetchall()]

            address_data = []
            for user_id in user_ids:
                title = fake.random_element(["home", "office"])

                # Fetching a random city
                self.cur.execute("SELECT id, province_id FROM cities ORDER BY RANDOM() LIMIT 1")
                city_id, province_id = self.cur.fetchone()

                # Generate a realistic address
                street_address = fake.street_address()
                other_address_elements = fake.secondary_address()
                full_address = f"{street_address}, {other_address_elements}"

                address_data.append((title, user_id, province_id, city_id, full_address))

            query = "INSERT INTO addresses (title, user_id, province_id, city_id, full_address) VALUES %s"
            execute_values(self.cur, query, address_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating addresses: {e}")


def main():
    address_model_generator = Address()
    address_model_generator.generate_addresses()


if __name__ == "__main__":
    main()
