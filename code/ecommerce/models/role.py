import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config


class Role(object):
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def generate_roles(self):
        try:
            role_data = [
                ('admin', 'Administrator'),
                ('staff', 'Staff'),
                ('manager', 'Manager'),
                ('customer', 'Customer'),
            ]
            self.cur.execute("SELECT COUNT(*) FROM roles")
            count = self.cur.fetchone()[0]

            if count == 0:
                query = "INSERT INTO roles (role_name, role_title) VALUES %s"
                execute_values(self.cur, query, role_data)
                self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while generating roles: {e}")


def main():
    role_model_generator = Role()
    role_model_generator.generate_roles()


if __name__ == "__main__":
    main()
