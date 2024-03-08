import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config
import random
from datetime import datetime, timedelta


class AdsCampaigns:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_ad_campaigns(self, num_campaigns):
        try:
            ad_campaign_data = []
            for _ in range(num_campaigns):
                # Generate random start date within the past month
                start_date = datetime.now() - timedelta(days=random.randint(1, 30))

                # Generate end date within a maximum duration of 10 days from start date
                end_date = start_date + timedelta(days=random.randint(1, 10))

                campaign_title = f"Campaign_{random.randint(1, 1000)}"

                ad_campaign_data.append((campaign_title, start_date, end_date))

            insert_query = """
                INSERT INTO adscampaigns (campaign_title, started_at, expired_at)
                VALUES %s
            """
            execute_values(self.cur, insert_query, ad_campaign_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating ad campaigns: {e}")


def main():
    ad_campaigns_model_generator = AdsCampaigns()
    ad_campaigns_model_generator.generate_ad_campaigns(20)


if __name__ == "__main__":
    main()
