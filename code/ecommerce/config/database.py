import os

# Docker DB configs
db_config = {
    'dbname': os.getenv('POSTGRES_DB'),
    'user': os.getenv('POSTGRES_USER'),
    'password': os.getenv('POSTGRES_PASSWORD'),
    'host': os.getenv('POSTGRES_HOST'),
    'port': os.getenv('POSTGRES_PORT'),
}

# Local DB configs
# db_config = {
#     'dbname': 'ecommerce',
#     'user': 'postgres',
#     'password': 1433,
#     'host': 'localhost',
#     'port': '5432',
# }
