import psycopg2
from psycopg2.extras import execute_values
from ecommerce.config.database import db_config


class RoleUser:
    def __init__(self):
        self.conn = psycopg2.connect(**db_config)
        self.cur = self.conn.cursor()

    def __del__(self):
        self.cur.close()
        self.conn.close()

    def assign_roles_to_users(self):
        try:

            # Fetching role IDs for respective roles
            self.cur.execute("SELECT id FROM roles WHERE role_name = 'admin'")
            admin_role_id = self.cur.fetchone()[0]

            self.cur.execute("SELECT id FROM roles WHERE role_name = 'manager'")
            manager_role_id = self.cur.fetchone()[0]

            self.cur.execute("SELECT id FROM roles WHERE role_name = 'staff'")
            staff_role_id = self.cur.fetchone()[0]

            self.cur.execute("SELECT id FROM roles WHERE role_name = 'customer'")
            customer_role_id = self.cur.fetchone()[0]

            # Fetching user IDs from the users table
            self.cur.execute("SELECT id FROM users WHERE NOT EXISTS"
                             "(SELECT user_id FROM role_user WHERE user_id = users.id)")
            user_ids = [row[0] for row in self.cur.fetchall()]

            self.cur.execute("SELECT count(id) FROM role_user WHERE role_id = %s",(admin_role_id,))
            admin_role_count = self.cur.fetchone()[0]

            self.cur.execute("SELECT count(id) FROM role_user WHERE role_id = %s", (manager_role_id,))
            manager_role_count = self.cur.fetchone()[0]

            self.cur.execute("SELECT count(id) FROM role_user WHERE role_id = %s",(staff_role_id,))
            staff_role_count = self.cur.fetchone()[0]

            # Assigning roles to users based on specifications
            role_data = []

            for user_id in user_ids:
                if admin_role_count == 0:
                    role_data.append((admin_role_id, user_id))
                elif manager_role_count < 2:
                    role_data.append((manager_role_id, user_id))
                elif staff_role_count < 4:
                    role_data.append((staff_role_id, user_id))
                else:
                    role_data.append((customer_role_id, user_id))

            query = "INSERT INTO role_user (role_id, user_id) VALUES %s"
            execute_values(self.cur, query, role_data)
            self.conn.commit()

        except Exception as e:
            self.conn.rollback()
            print(f"Error while assigning roles: {e}")


def main():
    role_user_model_generator = RoleUser()
    role_user_model_generator.assign_roles_to_users()


if __name__ == "__main__":
    main()
