#!/bin/bash
####################################
#
# Install script for Authentication Server
#
####################################

# General install

  
# ip="$(ip -f inet addr show eth1 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')"
user=$1
pass=$2
ip=$3
database="sensethis"
account="postgres"

curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y nodejs
sudo apt-get install postgresql-12 -y
npm install oauth2-server - y

npm install pm2 -g
pm2 install pm2-metrics
pm2 install pm2-logrotate

sed -i "s/0.0.0.0/$ip/" ~/.pm2/modules/pm2-metrics/node_modules/pm2-metrics/exporter.js
sed -i "s/0.0.0.0/10.116.0.11/" ~/.pm2/modules/pm2-metrics/node_modules/pm2-metrics/exporter.js
pm2 restart pm2-metrics

# `lsb_release -c -s` should return the correct codename of your OS
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -c -s)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update

# Add our PPA
sudo add-apt-repository ppa:timescale/timescaledb-ppa -y
sudo apt-get update

# Now install appropriate package for PG version
sudo apt install timescaledb-postgresql-12 -y

sudo service postgresql restart

# Installation of Node Exporter to INTRA-NET IP

wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz -O /node_exporter_zip.tar.gz
tar xvfz /node_exporter_zip.tar.gz -C /
mv /node_exporter-1.0.1.linux-amd64 /node_exporter
rm /node_exporter_zip.tar.gz

touch /etc/systemd/system/node_exporter.service

echo "[Unit]" >> /etc/systemd/system/node_exporter.service
echo "Description=Node_Exporter" >> /etc/systemd/system/node_exporter.service
echo "After=network-online.target" >> /etc/systemd/system/node_exporter.service
echo "" >> /etc/systemd/system/node_exporter.service
echo "[Service]" >> /etc/systemd/system/node_exporter.service
echo "User=root" >> /etc/systemd/system/node_exporter.service
echo "Restart=on-failure" >> /etc/systemd/system/node_exporter.service
echo "ExecStart=/node_exporter/node_exporter  --collector.netstat.fields=(.*) --collector.vmstat.fields=(.*) --collector.interrupts --web.listen-address=$ip:9100" >> /etc/systemd/system/node_exporter.service
echo "[Install]" >> /etc/systemd/system/node_exporter.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/node_exporter.service

systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service

# Installation of Postgres_Exporter 

wget https://github.com/wrouesnel/postgres_exporter/releases/download/v0.8.0/postgres_exporter_v0.8.0_linux-amd64.tar.gz
tar xvfz postgres_exporter_v0.8.0_linux-amd64.tar.gz
mv /root/postgres_exporter_v0.8.0_linux-amd64 /postgres_exporter
rm /root/postgres_exporter_v0.8.0_linux-amd64.tar.gz
touch /postgres_exporter/postgres-queries.yml
touch /etc/systemd/system/postgres_exporter.service

echo "[Unit]" >> /etc/systemd/system/postgres_exporter.service
echo "Description=Prometheus Postgres Exporter Server" >> /etc/systemd/system/postgres_exporter.service
echo "" >> /etc/systemd/system/postgres_exporter.service
echo "[Service]" >> /etc/systemd/system/postgres_exporter.service
echo "User=root" >> /etc/systemd/system/postgres_exporter.service
echo "Restart=on-failure" >> /etc/systemd/system/postgres_exporter.service
echo "Environment=\"DATA_SOURCE_NAME=postgresql://$1:$2@$ip:5432/$database\"" >> /etc/systemd/system/postgres_exporter.service
echo "ExecStart=/postgres_exporter/postgres_exporter --extend.query-path /postgres_exporter/postgres-queries.yml --web.listen-address=$ip:9187" >> /etc/systemd/system/postgres_exporter.service
echo "" >> /etc/systemd/system/postgres_exporter.service
echo "[Install]" >> /etc/systemd/system/postgres_exporter.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/postgres_exporter.service


echo "pg_replication:" >> /postgres_exporter/postgres-queries.yml
echo "  query: \"SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) as lag\"" >> /postgres_exporter/postgres-queries.yml
echo "  master: true" >> /postgres_exporter/postgres-queries.yml
echo "  metrics:" >> /postgres_exporter/postgres-queries.yml
echo "    - lag:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Replication lag behind master in seconds\"" >> /postgres_exporter/postgres-queries.yml
echo "" >> /postgres_exporter/postgres-queries.yml
echo "pg_postmaster:" >> /postgres_exporter/postgres-queries.yml
echo "  query: \"SELECT pg_postmaster_start_time as start_time_seconds from pg_postmaster_start_time()\"" >> /postgres_exporter/postgres-queries.yml
echo "  master: true" >> /postgres_exporter/postgres-queries.yml
echo "  metrics:" >> /postgres_exporter/postgres-queries.yml
echo "    - start_time_seconds:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Time at which postmaster started\"" >> /postgres_exporter/postgres-queries.yml
echo "" >> /postgres_exporter/postgres-queries.yml
echo "pg_stat_user_tables:" >> /postgres_exporter/postgres-queries.yml
echo "  query: \"SELECT current_database() datname, schemaname, relname, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, n_tup_upd, n_tup_del, n_tup_hot_upd, n_live_tup, n_dead_tup, n_mod_since_analyze, COALESCE(last_vacuum, '1970-01-01Z'), COALESCE(last_vacuum, '1970-01-01Z') as last_vacuum, COALESCE(last_autovacuum, '1970-01-01Z') as last_autovacuum, COALESCE(last_analyze, '1970-01-01Z') as last_analyze, COALESCE(last_autoanalyze, '1970-01-01Z') as last_autoanalyze, vacuum_count, autovacuum_count, analyze_count, autoanalyze_count FROM pg_stat_user_tables\"" >> /postgres_exporter/postgres-queries.yml
echo "  metrics:" >> /postgres_exporter/postgres-queries.yml
echo "    - datname:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"LABEL\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Name of current database\"" >> /postgres_exporter/postgres-queries.yml
echo "    - schemaname:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"LABEL\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Name of the schema that this table is in\"" >> /postgres_exporter/postgres-queries.yml
echo "    - relname:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"LABEL\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Name of this table\"" >> /postgres_exporter/postgres-queries.yml
echo "    - seq_scan:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of sequential scans initiated on this table\"" >> /postgres_exporter/postgres-queries.yml
echo "    - seq_tup_read:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of live rows fetched by sequential scans\"" >> /postgres_exporter/postgres-queries.yml
echo "    - idx_scan:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of index scans initiated on this table\"" >> /postgres_exporter/postgres-queries.yml
echo "    - idx_tup_fetch:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of live rows fetched by index scans\"" >> /postgres_exporter/postgres-queries.yml
echo "    - n_tup_ins:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of rows inserted\"" >> /postgres_exporter/postgres-queries.yml
echo "    - n_tup_upd:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of rows updated\"" >> /postgres_exporter/postgres-queries.yml
echo "    - n_tup_del:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of rows deleted\"" >> /postgres_exporter/postgres-queries.yml
echo "    - n_tup_hot_upd:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of rows HOT updated (i.e., with no separate index update required)\"" >> /postgres_exporter/postgres-queries.yml
echo "    - n_live_tup:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Estimated number of live rows\"" >> /postgres_exporter/postgres-queries.yml
echo "    - n_dead_tup:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Estimated number of dead rows\"" >> /postgres_exporter/postgres-queries.yml
echo "    - n_mod_since_analyze:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Estimated number of rows changed since last analyze\"" >> /postgres_exporter/postgres-queries.yml
echo "    - last_vacuum:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Last time at which this table was manually vacuumed (not counting VACUUM FULL)\"" >> /postgres_exporter/postgres-queries.yml
echo "    - last_autovacuum:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Last time at which this table was vacuumed by the autovacuum daemon\"" >> /postgres_exporter/postgres-queries.yml
echo "    - last_analyze:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Last time at which this table was manually analyzed\"" >> /postgres_exporter/postgres-queries.yml
echo "    - last_autoanalyze:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Last time at which this table was analyzed by the autovacuum daemon\"" >> /postgres_exporter/postgres-queries.yml
echo "    - vacuum_count:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of times this table has been manually vacuumed (not counting VACUUM FULL)\"" >> /postgres_exporter/postgres-queries.yml
echo "    - autovacuum_count:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of times this table has been vacuumed by the autovacuum daemon\"" >> /postgres_exporter/postgres-queries.yml
echo "    - analyze_count:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of times this table has been manually analyzed\"" >> /postgres_exporter/postgres-queries.yml
echo "    - autoanalyze_count:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of times this table has been analyzed by the autovacuum daemon\"" >> /postgres_exporter/postgres-queries.yml
echo "" >> /postgres_exporter/postgres-queries.yml
echo "pg_statio_user_tables:" >> /postgres_exporter/postgres-queries.yml
echo "  query: \"SELECT current_database() datname, schemaname, relname, heap_blks_read, heap_blks_hit, idx_blks_read, idx_blks_hit, toast_blks_read, toast_blks_hit, tidx_blks_read, tidx_blks_hit FROM pg_statio_user_tables\"" >> /postgres_exporter/postgres-queries.yml
echo "  metrics:" >> /postgres_exporter/postgres-queries.yml
echo "    - datname:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"LABEL\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Name of current database\"" >> /postgres_exporter/postgres-queries.yml
echo "    - schemaname:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"LABEL\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Name of the schema that this table is in\"" >> /postgres_exporter/postgres-queries.yml
echo "    - relname:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"LABEL\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Name of this table\"" >> /postgres_exporter/postgres-queries.yml
echo "    - heap_blks_read:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of disk blocks read from this table\"" >> /postgres_exporter/postgres-queries.yml
echo "    - heap_blks_hit:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of buffer hits in this table\"" >> /postgres_exporter/postgres-queries.yml
echo "    - idx_blks_read:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of disk blocks read from all indexes on this table\"" >> /postgres_exporter/postgres-queries.yml
echo "    - idx_blks_hit:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of buffer hits in all indexes on this table\"" >> /postgres_exporter/postgres-queries.yml
echo "    - toast_blks_read:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of disk blocks read from this table's TOAST table (if any)\"" >> /postgres_exporter/postgres-queries.yml
echo "    - toast_blks_hit:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of buffer hits in this table's TOAST table (if any)\"" >> /postgres_exporter/postgres-queries.yml
echo "    - tidx_blks_read:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of disk blocks read from this table's TOAST table indexes (if any)\"" >> /postgres_exporter/postgres-queries.yml
echo "    - tidx_blks_hit:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of buffer hits in this table's TOAST table indexes (if any)\"" >> /postgres_exporter/postgres-queries.yml
echo "        " >> /postgres_exporter/postgres-queries.yml
echo "pg_database:" >> /postgres_exporter/postgres-queries.yml
echo "  query: \"SELECT pg_database.datname, pg_database_size(pg_database.datname) as size_bytes FROM pg_database\"" >> /postgres_exporter/postgres-queries.yml
echo "  master: true" >> /postgres_exporter/postgres-queries.yml
echo "  cache_seconds: 30" >> /postgres_exporter/postgres-queries.yml
echo "  metrics:" >> /postgres_exporter/postgres-queries.yml
echo "    - datname:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"LABEL\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Name of the database\"" >> /postgres_exporter/postgres-queries.yml
echo "    - size_bytes:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Disk space used by the database\"" >> /postgres_exporter/postgres-queries.yml
echo "" >> /postgres_exporter/postgres-queries.yml
echo "pg_stat_statements:" >> /postgres_exporter/postgres-queries.yml
echo "  query: \"SELECT t2.rolname, t3.datname, queryid, calls, total_time / 1000 as total_time_seconds, min_time / 1000 as min_time_seconds, max_time / 1000 as max_time_seconds, mean_time / 1000 as mean_time_seconds, stddev_time / 1000 as stddev_time_seconds, rows, shared_blks_hit, shared_blks_read, shared_blks_dirtied, shared_blks_written, local_blks_hit, local_blks_read, local_blks_dirtied, local_blks_written, temp_blks_read, temp_blks_written, blk_read_time / 1000 as blk_read_time_seconds, blk_write_time / 1000 as blk_write_time_seconds FROM pg_stat_statements t1 join pg_roles t2 on (t1.userid=t2.oid) join pg_database t3 on (t1.dbid=t3.oid)\"" >> /postgres_exporter/postgres-queries.yml
echo "  master: true" >> /postgres_exporter/postgres-queries.yml
echo "  metrics:" >> /postgres_exporter/postgres-queries.yml
echo "    - rolname:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"LABEL\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Name of user\"" >> /postgres_exporter/postgres-queries.yml
echo "    - datname:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"LABEL\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Name of database\"" >> /postgres_exporter/postgres-queries.yml
echo "    - queryid:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"LABEL\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Query ID\"" >> /postgres_exporter/postgres-queries.yml
echo "    - calls:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Number of times executed\"" >> /postgres_exporter/postgres-queries.yml
echo "    - total_time_seconds:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total time spent in the statement, in milliseconds\"" >> /postgres_exporter/postgres-queries.yml
echo "    - min_time_seconds:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Minimum time spent in the statement, in milliseconds\"" >> /postgres_exporter/postgres-queries.yml
echo "    - max_time_seconds:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Maximum time spent in the statement, in milliseconds\"" >> /postgres_exporter/postgres-queries.yml
echo "    - mean_time_seconds:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Mean time spent in the statement, in milliseconds\"" >> /postgres_exporter/postgres-queries.yml
echo "    - stddev_time_seconds:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"GAUGE\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Population standard deviation of time spent in the statement, in milliseconds\"" >> /postgres_exporter/postgres-queries.yml
echo "    - rows:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of rows retrieved or affected by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - shared_blks_hit:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of shared block cache hits by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - shared_blks_read:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of shared blocks read by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - shared_blks_dirtied:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of shared blocks dirtied by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - shared_blks_written:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of shared blocks written by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - local_blks_hit:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of local block cache hits by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - local_blks_read:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of local blocks read by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - local_blks_dirtied:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of local blocks dirtied by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - local_blks_written:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of local blocks written by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - temp_blks_read:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of temp blocks read by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - temp_blks_written:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total number of temp blocks written by the statement\"" >> /postgres_exporter/postgres-queries.yml
echo "    - blk_read_time_seconds:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total time the statement spent reading blocks, in milliseconds (if track_io_timing is enabled, otherwise zero)\"" >> /postgres_exporter/postgres-queries.yml
echo "    - blk_write_time_seconds:" >> /postgres_exporter/postgres-queries.yml
echo "        usage: \"COUNTER\"" >> /postgres_exporter/postgres-queries.yml
echo "        description: \"Total time the statement spent writing blocks, in milliseconds (if track_io_timing is enabled, otherwise zero)\"" >> /postgres_exporter/postgres-queries.yml

sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/' /etc/postgresql/12/main/pg_hba.conf
echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/12/main/pg_hba.conf
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '$ip'/" /etc/postgresql/12/main/postgresql.conf
sed -i "s/#wal_level = logical                    # minimal, replica, or logical/wal_level = logical                     # minimal, replica, or logical/" /etc/postgresql/12/main/postgresql.conf

sudo service postgresql restart

psql -U $account -c "CREATE DATABASE $database;"
psql -U $account -c "CREATE USER $user PASSWORD '$pass';"
psql -U $account -c "ALTER USER $user WITH SUPERUSER;"

systemctl daemon-reload
systemctl enable node_exporter.service
systemctl enable postgres_exporter.service
systemctl start node_exporter.service
systemctl start postgres_exporter.service


