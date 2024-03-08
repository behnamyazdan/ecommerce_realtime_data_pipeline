import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config
from faker import Faker
from geopy.geocoders import Nominatim


class City:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_cities_for_provinces(self):
        fake = Faker('en_US')  # Set the Faker instance to generate US-specific data
        geolocator = Nominatim(user_agent="city_generator")
        try:
            # Fetch existing province IDs from the provinces table
            self.cur.execute("SELECT id FROM provinces")
            province_ids = [row[0] for row in self.cur.fetchall()]

            for province_id in province_ids:
                # Generate a random number of cities (between 2 and 10) for each province
                num_cities = fake.random_int(min=2, max=15)
                city_data = []
                for _ in range(num_cities):
                    city_name = fake.city()
                    location = geolocator.geocode(city_name + ", USA")
                    if location:
                        latitude = location.latitude
                        longitude = location.longitude
                        city_data.append((city_name, province_id, latitude, longitude))
                if city_data:
                    query = ("INSERT INTO cities (city_name, province_id, latitude, longitude)"
                             "VALUES %s ON CONFLICT DO NOTHING")
                    execute_values(self.cur, query, city_data)
                    self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating cities: {e}")


def main():
    city_model_generator = City()
    city_model_generator.generate_cities_for_provinces()


if __name__ == "__main__":
    main()
