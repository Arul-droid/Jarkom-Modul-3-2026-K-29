# Panduan & Dokumentasi Skrip Jarkom Modul 3 (Kelompok K-29)

Dokumen ini berisi daftar lengkap skrip otomatisasi konfigurasi jaringan, layanan DHCP, DNS BIND9, Database Replikasi MariaDB, Web Frontend Nginx/PHP-FPM, Internal Load Balancer, Public Reverse Proxy, serta benchmark pengujian performa sesuai modul praktikum dan backup command konfigurasi.

---

## 1. Glosarium Entitas & Tabel Pemetaan Node

| Nama Node | Peran / Fungsi | Antarmuka | IP Address / Subnet | Keterangan / MAC Address |
| :--- | :--- | :--- | :--- | :--- |
| **jichi** | Router Utama & DHCP Relay | `eth0`<br>`eth1`<br>`eth2`<br>`eth3`<br>`eth4` | DHCP (NAT WAN)<br>`10.78.1.1/24`<br>`10.78.2.1/24`<br>`10.78.3.1/24`<br>`10.78.4.1/24` | Gateway Network 1<br>Gateway Network 2 (Divisi A)<br>Gateway Network 3 (Divisi B)<br>Gateway Network 4 (Data Center) |
| **tengen** | DHCP Server (ISC DHCP) | `eth0` | `10.78.4.10/24` | Server DHCP untuk Network 2 & 3 |
| **utahime** | DNS Server Master | `eth0` | `10.78.1.2/24` | Master zone `jujutsu.k29.com` |
| **shoko** | DNS Server Slave | `eth0` | `10.78.1.3/24` | Slave zone `jujutsu.k29.com` |
| **gojo** | Public Reverse Proxy (Nginx) | `eth0` | `10.78.1.4/24` | Entry point domain publik `jujutsu.k29.com` |
| **geto** | Internal Load Balancer (Nginx) | `eth0` | `10.78.4.2/24` | LB internal API Worker (WRR 3:1) |
| **yaga** | Database Master (MariaDB) | `eth0` | `10.78.4.9/24` | DB Master `db_shibuya_k29` (Binlog active) |
| **inumaki** | Database Slave (MariaDB) | `eth0` | `10.78.4.21/24` | DB Slave `db_shibuya_k29` (Replication active) |
| **maki** | Worker Web Frontend | `eth0` | `10.78.4.12/24` | Nginx + PHP-FPM (Hanya allow dari Gojo) |
| **panda** | Worker Web Frontend | `eth0` | `10.78.4.13/24` | Nginx + PHP-FPM (Hanya allow dari Gojo) |
| **nanami** | Worker API Utama | `eth0` | `10.78.4.14/24` | API Worker (Weight=3, log ke Yaga) |
| **todo** | Worker API Utama | `eth0` | `10.78.4.15/24` | API Worker (Weight=1, log ke Yaga) |
| **kirara** | Worker API Cadangan | `eth0` | `10.78.4.16/24` | Backup API Worker (Failover) |
| **itadori** | Klien Divisi A (Pool 1) | `eth0` | DHCP (`10.78.2.10`–`35`) | MAC: `02:42:24:21:1a:00` |
| **fushiguro** | Klien Divisi A (Pool 1) | `eth0` | DHCP (`10.78.2.10`–`35`) | MAC: `02:42:30:24:4c:00` |
| **zenin** | Klien Divisi A (Pool 2) | `eth0` | DHCP (`10.78.2.70`–`95`) | MAC: `02:42:28:b9:c0:00` |
| **okkotsu** | Klien Divisi A (Pool 2) | `eth0` | DHCP (`10.78.2.70`–`95`) | MAC: `02:42:d3:fe:e9:00` |
| **ino** | Klien Divisi B (Short Lease) | `eth0` | DHCP (`10.78.3.10`–`89`) | MAC: `02:42:8a:f1:0f:00` (1800s) |
| **kusakabe** | Klien Divisi B (Short Lease) | `eth0` | DHCP (`10.78.3.10`–`89`) | MAC: `02:42:a5:de:b3:00` (1800s) |
| **miwa** | Klien Divisi B (Long Lease) | `eth0` | DHCP (`10.78.3.100`–`199`) | MAC: `02:42:80:41:bf:00` (43200s) |
| **kugisaki** | Klien Divisi B (VIP Fixed IP) | `eth0` | Static DHCP (`10.78.3.99`) | MAC: `02:42:8f:4e:be:00` |

---

## 2. Struktur Direktori Skrip

Seluruh skrip dikelompokkan ke dalam direktori berdasarkan nama nodenya masing-masing:

```text
script/
├── README.md                 # Dokumentasi ini
├── jichi/                    # Router Utama & DHCP Relay
│   ├── soal1.sh              # Inisialisasi interface, routing & NAT Masquerade
│   ├── soal3.sh              # Setup isc-dhcp-relay
│   └── autostart.sh          # Konfigurasi autostart .bashrc (Soal 10)
├── tengen/                   # DHCP Server (Data Center)
│   ├── soal1.sh              # Setup IP Statis 10.78.4.10
│   ├── soal2.sh              # Setup awal isc-dhcp-server
│   ├── soal4.sh              # Multi-pool Tim Dev & Support (Divisi A)
│   ├── soal5.sh              # Short & Long lease time + DNS options (Divisi B)
│   ├── soal6.sh              # Host reservation static lease Kugisaki
│   ├── soal7.sh              # Validasi dhcpd.leases
│   ├── soal8.sh              # Packet capture tcpdump DORA protocol
│   └── autostart.sh          # Konfigurasi autostart .bashrc (Soal 10)
├── utahime/                  # DNS Master
│   ├── soal1.sh              # Setup IP Statis 10.78.1.2
│   ├── soal11.sh             # BIND9 Master zone jujutsu.k29.com
│   └── soal12.sh             # A, CNAME www, PTR reverse zone, & DNS Forwarder
├── shoko/                    # DNS Slave
│   ├── soal1.sh              # Setup IP Statis 10.78.1.3
│   └── soal11.sh             # BIND9 Slave zone transfer dari Utahime
├── gojo/                     # Public Reverse Proxy
│   ├── soal1.sh              # Setup IP Statis 10.78.1.4
│   ├── setup_gojo16.sh       # Reverse proxy Nginx routing / dan /api
│   ├── config_gojo.sh        # Routing dengan X-Real-IP & X-Forwarded-For (Soal 17)
│   └── soal19_gojo.sh        # Proxy Caching & Rate Limiting (Soal 19)
├── geto/                     # Internal Load Balancer
│   ├── soal1.sh              # Setup IP Statis 10.78.4.2
│   ├── setup.sh              # Nginx LB Weighted Round Robin 3:1 (Soal 15)
│   ├── config_geto.sh        # Modul Real-IP hanya mempercayai Gojo (Soal 17)
│   └── soal18_geto.sh        # Passive health check & failover Kirara (Soal 18)
├── yaga/                     # Database Master (MariaDB)
│   ├── soal1.sh              # Setup IP Statis 10.78.4.9
│   └── setup_yaga.sh         # MariaDB Master, Binlog, user & db_shibuya_k29
├── inumaki/                  # Database Slave (MariaDB)
│   ├── soal1.sh              # Setup IP Statis 10.78.4.21
│   └── setup_inumaki.sh      # MariaDB Slave, CHANGE MASTER TO Yaga
├── maki/                     # Frontend Worker 1
│   ├── soal1.sh              # Setup IP Statis 10.78.4.12
│   └── setup_frontend.sh     # Nginx + PHP-FPM, restriksi allow Gojo
├── panda/                    # Frontend Worker 2
│   ├── soal1.sh              # Setup IP Statis 10.78.4.13
│   └── setup_frontend.sh     # Nginx + PHP-FPM, restriksi allow Gojo
├── nanami/                   # API Worker Utama 1
│   ├── soal1.sh              # Setup IP Statis 10.78.4.14
│   ├── setup.sh              # Nginx web server awal
│   └── setup_api_worker.sh   # API endpoint, database logger & real-ip
├── todo/                     # API Worker Utama 2
│   ├── soal1.sh              # Setup IP Statis 10.78.4.15
│   ├── setup.sh              # Nginx web server awal
│   └── setup_api_worker.sh   # API endpoint, database logger & real-ip
├── kirara/                   # API Worker Cadangan (Backup)
│   ├── soal1.sh              # Setup IP Statis 10.78.4.16
│   └── setup_api_worker.sh   # API endpoint, database logger & real-ip
├── itadori/                  # Client Network 2
│   ├── soal3.sh              # udhcpc client request lease
│   ├── soal7.sh              # Validasi IP, subnet, gateway, DNS
│   └── uji_klien.sh          # Uji DNS, CNAME, PTR, Forwarder, dan akses HTTP
├── fushiguro/                # Client Network 2
│   ├── soal3.sh              # udhcpc client request lease
│   └── soal7.sh              # Validasi konfigurasi jaringan
├── zenin/                    # Client Network 2
│   ├── soal3.sh              # udhcpc client request lease
│   └── soal7.sh              # Validasi konfigurasi jaringan
├── okkotsu/                  # Client Network 2
│   ├── soal3.sh              # udhcpc client request lease
│   └── soal7.sh              # Validasi konfigurasi jaringan
├── ino/                      # Client Network 3
│   ├── soal3.sh              # udhcpc client request lease
│   └── soal7.sh              # Validasi konfigurasi jaringan
├── kusakabe/                 # Client Network 3
│   ├── soal3.sh              # udhcpc client request lease
│   ├── soal7.sh              # Validasi konfigurasi jaringan
│   └── benchmark.sh          # Audit Apache Benchmark (Soal 20)
├── miwa/                     # Client Network 3
│   ├── soal3.sh              # udhcpc client request lease
│   └── soal7.sh              # Validasi konfigurasi jaringan
└── kugisaki/                 # Client VIP Network 3
    ├── soal3.sh              # udhcpc client renew static lease (10.78.3.99)
    └── soal7.sh              # Validasi konfigurasi jaringan
```

---

## 3. Panduan Eksekusi Langkah demi Langkah (Soal 1 – 20)

### Soal 1: Konfigurasi Dasar Jichi (Gateway & NAT) dan Host Infrastruktur
1. **Pada node Jichi:**
   ```bash
   chmod +x /root/soal1.sh && /root/soal1.sh
   ```
2. **Pada node infrastruktur Network 1 & 4:**
   - Jalankan `/root/soal1.sh` pada masing-masing node (`tengen`, `utahime`, `shoko`, `gojo`, `geto`, `yaga`, `inumaki`, `maki`, `panda`, `nanami`, `todo`, `kirara`).
   - Seluruh node akan memiliki IP statis, default gateway ke Jichi, serta nameserver internet `192.168.122.1`.

---

### Soal 2: Konfigurasi DHCP Server pada Tengen
1. **Pada node Tengen:**
   ```bash
   chmod +x /root/soal2.sh && /root/soal2.sh
   ```
2. Memverifikasi status `isc-dhcp-server`:
   ```bash
   service isc-dhcp-server status
   ```

---

### Soal 3: Konfigurasi DHCP Relay pada Jichi & Uji Klien
1. **Pada node Jichi:**
   ```bash
   chmod +x /root/soal3.sh && /root/soal3.sh
   ps aux | grep dhcrelay
   ```
2. **Pada klien Network 2 & 3 (misal Itadori):**
   ```bash
   chmod +x /root/soal3.sh && /root/soal3.sh
   ```
   Klien akan mendapatkan IP dinamis dari DHCP Server Tengen melalui Router Jichi.

---

### Soal 4: Multi-Pool DHCP Berdasarkan MAC Address di Network 2 (Divisi A)
1. **Pada node Tengen:**
   ```bash
   chmod +x /root/soal4.sh && /root/soal4.sh
   ```
2. **Pada klien Network 2:**
   - `itadori` & `fushiguro` (Pool 1) -> Mendapatkan IP di rentang `10.78.2.10`–`10.78.2.35`.
   - `zenin` & `okkotsu` (Pool 2) -> Mendapatkan IP di rentang `10.78.2.70`–`10.78.2.95`.

---

### Soal 5: Konfigurasi Lease Time & Options di Network 3 (Divisi B)
1. **Pada node Tengen:**
   ```bash
   chmod +x /root/soal5.sh && /root/soal5.sh
   ```
2. **Pada klien Network 3:**
   - `ino` & `kusakabe` -> Short lease (1800 detik / 30 menit), IP `10.78.3.10`–`10.78.3.89`.
   - `miwa` -> Long lease (43200 detik / 12 jam), IP `10.78.3.100`–`10.78.3.199`.
   - Keduanya menerima DNS Server `10.78.1.2`, `10.78.1.3` dan domain `k29.com`.

---

### Soal 6: Static Lease (Fixed Address) Personel VIP Kugisaki
1. **Pada node Tengen:**
   ```bash
   chmod +x /root/soal6.sh && /root/soal6.sh
   ```
2. **Pada node Kugisaki:**
   ```bash
   chmod +x /root/soal3.sh && /root/soal3.sh
   ```
   Kugisaki akan menerima alamat tetap `10.78.3.99/24`.

---

### Soal 7: Validasi Konfigurasi Jaringan Klien dan Database Lease
1. **Pada klien Network 2 & 3 (`itadori`, `zenin`, `ino`, `miwa`, dll.):**
   ```bash
   chmod +x /root/soal7.sh && /root/soal7.sh
   ```
2. **Pada node Tengen:**
   ```bash
   chmod +x /root/soal7.sh && /root/soal7.sh
   ```

---

### Soal 8: Packet Capture Protokol DORA
1. **Pada node Tengen, jalankan capture:**
   ```bash
   chmod +x /root/soal8.sh && /root/soal8.sh
   ```
2. **Pada node klien (misal Itadori), trigger permintaan lease baru:**
   ```bash
   ip addr flush dev eth0 && udhcpc -i eth0
   ```
3. Amati proses DHCP Discover, Offer, Request, dan ACK di terminal Tengen.

---

### Soal 9: Simulasi Gangguan dan Pemulihan DHCP Relay
1. **Pada node Jichi (Hentikan relay):**
   ```bash
   service isc-dhcp-relay stop
   ```
2. **Pada klien (Itadori):**
   ```bash
   ip addr flush dev eth0 && udhcpc -i eth0
   ```
   Hasil: Klien mengalami timeout (`udhcpc failed to get a DHCP lease`).
3. **Pada node Jichi (Pulihkan relay):**
   ```bash
   service isc-dhcp-relay start
   ```
4. **Pada klien (Itadori):**
   ```bash
   udhcpc -i eth0 && ip a show eth0
   ```
   Hasil: Klien kembali menerima alokasi IP yang valid.

---

### Soal 10: Autostart / Persistensi Layanan Pasca-Reboot
1. **Pada Jichi:**
   ```bash
   chmod +x /root/autostart.sh && /root/autostart.sh
   ```
2. **Pada Tengen:**
   ```bash
   chmod +x /root/autostart.sh && /root/autostart.sh
   ```
3. Restart kedua node (`reboot`), lalu verifikasi layanan otomatis aktif setelah startup.

---

### Soal 11: DNS Master (Utahime) & DNS Slave (Shoko)
1. **Pada node Utahime (Master):**
   ```bash
   chmod +x /root/soal11.sh && /root/soal11.sh
   ```
2. **Pada node Shoko (Slave):**
   ```bash
   chmod +x /root/soal11.sh && /root/soal11.sh
   ```
3. **Uji sinkronisasi zona:**
   Periksa file zona di Shoko: `cat /var/lib/bind/jujutsu.k29.com`.

---

### Soal 12: A Record, CNAME, Reverse DNS (PTR), & DNS Forwarder
1. **Pada node Utahime:**
   ```bash
   chmod +x /root/soal12.sh && /root/soal12.sh
   ```
2. **Uji dari klien (Itadori):**
   ```bash
   dig @10.78.1.2 www.jujutsu.k29.com
   dig @10.78.1.2 -x 10.78.1.4
   dig @10.78.1.2 google.com
   ping -c 3 google.com
   ```

---

### Soal 13: Database Master-Slave MariaDB (Yaga & Inumaki)
1. **Pada node Yaga (Master):**
   ```bash
   chmod +x /root/setup_yaga.sh && /root/setup_yaga.sh
   ```
   Catat file binlog dan posisinya (misal: `mariadb-bin.000001` posisi `654`).
2. **Pada node Inumaki (Slave):**
   - Sesuaikan `LOG_FILE` dan `LOG_POS` di `/root/setup_inumaki.sh` jika posisi berbeda.
   - Eksekusi:
     ```bash
     chmod +x /root/setup_inumaki.sh && /root/setup_inumaki.sh
     ```
3. **Uji replikasi:**
   - Insert di Yaga:
     ```bash
     mariadb -u root -D db_shibuya_k29 -e "INSERT INTO request_logs (worker_name, client_ip) VALUES ('demo_praktikum', '10.78.2.99');"
     ```
   - Cek di Inumaki:
     ```bash
     mariadb -u root -D db_shibuya_k29 -e "SELECT * FROM request_logs;"
     ```

---

### Soal 14: Web Frontend (Maki, Panda) & API Worker (Nanami, Todo, Kirara)
1. **Pada node Maki & Panda (Frontend):**
   ```bash
   chmod +x /root/setup_frontend.sh && /root/setup_frontend.sh
   ```
2. **Pada node Nanami, Todo, Kirara (API Worker):**
   ```bash
   chmod +x /root/setup_api_worker.sh && /root/setup_api_worker.sh
   ```
3. **Uji restriksi akses:**
   - Akses langsung dari klien (misal Itadori) ke `http://10.78.4.12/` -> **Ditolak (403 Forbidden)**.
   - Akses langsung dari klien ke `http://10.78.4.14/api` -> **Ditolak (403 Forbidden)**.

---

### Soal 15: Internal Load Balancer Weighted Round Robin (Geto)
1. **Pada node Geto:**
   ```bash
   chmod +x /root/setup.sh && /root/setup.sh
   ```
2. **Uji distribusi beban dari Tengen:**
   ```bash
   for i in $(seq 1 12); do curl -s http://10.78.4.2/; echo ""; done
   ```
   Distribusi respon akan menunjukkan rasio 3:1 (9 respons Nanami dan 3 respons Todo).

---

### Soal 16 & 17: Reverse Proxy Gojo & Pelacakan Real IP Klien
1. **Pada node Gojo:**
   ```bash
   chmod +x /root/config_gojo.sh && /root/config_gojo.sh
   ```
2. **Pada node Geto:**
   ```bash
   chmod +x /root/config_geto.sh && /root/config_geto.sh
   ```
3. **Pengujian dari klien Network 2 & 3:**
   ```bash
   curl -i http://jujutsu.k29.com/api
   ```
4. **Verifikasi penyimpanan log IP di database Yaga:**
   ```bash
   mariadb -u root -e "USE db_shibuya_k29; SELECT * FROM request_logs ORDER BY id DESC LIMIT 5;"
   ```
   Kolom `client_ip` mencatat alamat asli klien (`10.78.2.x` / `10.78.3.x`), bukan IP proxy Gojo (`10.78.1.4`) atau Geto (`10.78.4.2`).

---

### Soal 18: Passive Health Check & Failover Backup Worker (Kirara)
1. **Pada node Geto:**
   ```bash
   chmod +x /root/soal18_geto.sh && /root/soal18_geto.sh
   ```
2. **Simulasi gangguan (Matikan Nginx pada Nanami & Todo):**
   - Pada Nanami: `service nginx stop`
   - Pada Todo: `service nginx stop`
3. **Kirim request dari klien:**
   ```bash
   curl -i http://jujutsu.k29.com/api
   ```
   Respons otomatis ditangani oleh **kirara** tanpa error `502 Bad Gateway`.

---

### Soal 19: Nginx Proxy Caching & Rate Limiting pada Gojo
1. **Pada node Gojo:**
   ```bash
   chmod +x /root/soal19_gojo.sh && /root/soal19_gojo.sh
   ```
2. **Uji Caching:**
   - Request 1: `curl -I http://jujutsu.k29.com/` -> Header `X-Cache-Status: MISS`
   - Request 2: `curl -I http://jujutsu.k29.com/` -> Header `X-Cache-Status: HIT`
3. **Uji Rate Limiting (Kirim request bertubi-tubi):**
   ```bash
   for i in $(seq 1 20); do curl -s -o /dev/null -w "%{http_code}\n" http://jujutsu.k29.com/api; done
   ```
   Request di atas 10 req/s akan menghasilkan HTTP Status `429 Too Many Requests` (atau `503 Service Unavailable`).

---

### Soal 20: Audit & Benchmark Kapasitas Layanan via Kusakabe
1. **Pada node Kusakabe:**
   ```bash
   chmod +x /root/benchmark.sh && /root/benchmark.sh
   ```
2. Menghasilkan laporan metrik RPS, average latency, transfer rate, dan persentase sukses request.

