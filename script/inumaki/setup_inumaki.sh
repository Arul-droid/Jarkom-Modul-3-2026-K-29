#!/bin/bash

# 1. DNS untuk instalasi paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi MariaDB
apt-get update
apt-get install -y mariadb-server

# 3. Siapkan direktori kerja MariaDB
mkdir -p /run/mysqld /var/log/mysql /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/log/mysql /var/lib/mysql
chmod -R 755 /run/mysqld /var/log/mysql

# 4. Konfigurasi 50-server.cnf untuk Slave
cat << 'CNF' > /etc/mysql/mariadb.conf.d/50-server.cnf
[server]
[mysqld]
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
socket                  = /run/mysqld/mysqld.sock
port                    = 3306
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql
lc-messages             = en_US
skip-external-locking

bind-address            = 0.0.0.0

# Konfigurasi Slave (server-id wajib berbeda dari yaga)
server-id               = 2
relay-log               = /var/log/mysql/mariadb-relay-bin
log_bin                 = /var/log/mysql/mariadb-bin
binlog_do_db            = db_shibuya_k29
read_only               = 1

character-set-server    = utf8mb4
collation-server        = utf8mb4_general_ci
CNF

# 5. Restart layanan MariaDB
service mariadb restart

# 6. Variabel Replikasi (Sesuaikan LOG_FILE dan LOG_POS dengan output SHOW MASTER STATUS di yaga)
IP_YAGA="10.78.4.9"
LOG_FILE="mariadb-bin.000001"
LOG_POS=654

# 7. Konfigurasi Sinkronisasi Replikasi
mariadb -u root << SQL
STOP SLAVE;

CREATE DATABASE IF NOT EXISTS db_shibuya_k29;
USE db_shibuya_k29;

CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    worker_name VARCHAR(50),
    client_ip VARCHAR(45) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CHANGE MASTER TO
    MASTER_HOST='${IP_YAGA}',
    MASTER_USER='repl_user',
    MASTER_PASSWORD='repl_pass',
    MASTER_LOG_FILE='${LOG_FILE}',
    MASTER_LOG_POS=${LOG_POS};

START SLAVE;
SQL

# 8. Cek status replikasi
echo "=== CEK STATUS REPLIKASI SLAVE ==="
mariadb -u root -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running:|Slave_SQL_Running:|Last_Error:"
