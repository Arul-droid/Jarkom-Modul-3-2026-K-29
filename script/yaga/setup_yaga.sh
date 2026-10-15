#!/bin/bash
# 1. Pastikan nameserver awal aktif untuk instalasi paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi MariaDB Server
apt-get update
apt-get install -y mariadb-server

# 3. Siapkan direktori kerja dan izin akses log (Mencegah error socket/index)
mkdir -p /run/mysqld /var/log/mysql /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/log/mysql /var/lib/mysql
chmod -R 755 /run/mysqld /var/log/mysql

# 4. Konfigurasi 50-server.cnf (Buka bind-address & aktifkan Binary Logging)
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

# Mengizinkan akses remote dari Network 4
bind-address            = 0.0.0.0

# Konfigurasi Master & Binary Logging
server-id               = 1
log_bin                 = /var/log/mysql/mariadb-bin
binlog_do_db            = db_shibuya_k29

expire_logs_days        = 10
character-set-server    = utf8mb4
collation-server        = utf8mb4_general_ci

[embedded]
[mariadb]
[mariadb-10.5]
CNF

# 5. Restart layanan MariaDB untuk memuat konfigurasi baru
service mariadb restart

# 6. Konfigurasi User, Hak Akses Network 4, Database, dan Tabel
PREFIX_IP="10.78"

mariadb -u root << SQL
-- Buat user khusus untuk replikasi Slave (inumaki)
CREATE USER IF NOT EXISTS 'repl_user'@'${PREFIX_IP}.4.%' IDENTIFIED BY 'repl_pass';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'${PREFIX_IP}.4.%';

-- Berikan hak akses remote bagi seluruh node di Network 4 (Worker API, dll)
CREATE USER IF NOT EXISTS 'shibuya_app'@'${PREFIX_IP}.4.%' IDENTIFIED BY 'shibuya_pass';
GRANT ALL PRIVILEGES ON db_shibuya_k29.* TO 'shibuya_app'@'${PREFIX_IP}.4.%';
FLUSH PRIVILEGES;

-- Buat database dan tabel request_logs
CREATE DATABASE IF NOT EXISTS db_shibuya_k29;
USE db_shibuya_k29;

CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    worker_name VARCHAR(50),
    client_ip VARCHAR(45) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
SQL

# 7. Tampilkan posisi Binary Log untuk dicatat ke Slave
echo "=== CATAT FILE DAN POSITION DI BAWAH INI UNTUK INUMAKI ==="
mariadb -u root -e "SHOW MASTER STATUS\G"
