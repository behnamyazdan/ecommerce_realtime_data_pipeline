import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config
import random
import string
from datetime import datetime, timedelta


class Discount:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def fetch_campaign_ids(self):
        self.cur.execute("SELECT id FROM adscampaigns")
        return [row[0] for row in self.cur.fetchall()]

    def generate_discounts(self, num_discounts):
        try:
            campaign_ids = self.fetch_campaign_ids()

            discount_data = []
            for _ in range(num_discounts):
                if campaign_ids:
                    # Randomly assign adscampaign_id as null or a value from the campaign IDs
                    adscampaign_id = random.choice([None] + campaign_ids)
                else:
                    adscampaign_id = None
                discount_type = random.choice(['percent', 'amount'])
                if discount_type == 'percent':
                    value = random.randint(1, 100)  # Value between 1 and 100 for percentage type
                else:
                    value = round(random.uniform(1, 1000), 2)  # Random value for amount type

                started_at = datetime.now() - timedelta(days=random.randint(1, 30))
                expired_at = started_at + timedelta(days=random.randint(1, 30))

                # Generate a unique code for each discount (10 characters)
                code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))

                discount_data.append((adscampaign_id, discount_type, value, started_at, expired_at, code))

            insert_query = """
                INSERT INTO discounts (adscampaign_id, type, value, started_at, expired_at, code)
                VALUES %s
            """
            execute_values(self.cur, insert_query, discount_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating discounts: {e}")


def main():
    num_discounts = 1  # Specify the number of discounts to generate
    discounts_model_generator = Discount()
    discounts_model_generator.generate_discounts(num_discounts)


if __name__ == "__main__":
    main()
