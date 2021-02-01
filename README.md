# Authentication Installation

Setup Instructions. This will install PostgreSQL 12+, setup node_exporter and postgres_exporter for prometheus metrics. Sets up database and superuser for database and changes network access to the database. NodeJS + NPM + PM2

- **Init load file**
  - chmod 755 auth_setup.sh
  - sudo ./auth_setup.sh [db_username] [db_password] local ip
  - sudo timescaledb-tune --quiet --yes
  - sudo service postgresql restart
  - passwd postgres
  - psql
  - CREATE USER replica REPLICATION LOGIN ENCRYPTED PASSWORD 'somepassword';
