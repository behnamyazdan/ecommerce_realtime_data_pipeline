import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config
from faker import Faker


class Province:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_us_states(self):
        fake = Faker('en_US')  # Set the Faker instance to generate US-specific data
        try:
            state_data = [(fake.state(),) for _ in range(50)]  # Generate 50 US state names

            query = "INSERT INTO provinces (province_name) VALUES %s ON CONFLICT DO NOTHING"
            execute_values(self.cur, query, state_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating US states: {e}")


def main():
    province_model_generator = Province()
    province_model_generator.generate_us_states()


if __name__ == "__main__":
    main()
