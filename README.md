# Jarkom-Modul-3-2026-K-29

## 1. Konfigurasi Dasar Jichi (Gateway & NAT) dan Host Infrastruktur

> Ketika Curtain menutup Shibuya, jalur komunikasi antar zona Jujutsu High terputus. Pulihkan konektivitas dasar dengan mengonfigurasi jichi: eth0 memperoleh WAN dari NAT, sedangkan eth1–eth4 menjadi gateway Network 1–4 sesuai tabel pemetaan. Aktifkan IPv4 forwarding dan source NAT, lalu tetapkan IP statis host infrastruktur sesuai tabel spesifikasi. Buktikan konektivitas setiap host ke gateway dan akses eksternal dari host yang relevan.

### Langkah Konfigurasi

#### A. Router Jichi
Pada node **jichi**, buat script `/root/soal1.sh` untuk mengatur antarmuka, routing, IP forwarding, serta iptables NAT:

```bash
nano /root/soal1.sh
```

```bash
#!/bin/bash
echo "Konfigurasi jichi dimulai..."

dhclient -v eth0

ip addr flush dev eth1; ip addr add 10.78.1.1/24 dev eth1; ip link set eth1 up
ip addr flush dev eth2; ip addr add 10.78.2.1/24 dev eth2; ip link set eth2 up
ip addr flush dev eth3; ip addr add 10.78.3.1/24 dev eth3; ip link set eth3 up
ip addr flush dev eth4; ip addr add 10.78.4.1/24 dev eth4; ip link set eth4 up

echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

apt-get update
apt-get install -y iptables

iptables -t nat -F
iptables -F FORWARD
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -P FORWARD ACCEPT

echo "Konfigurasi jichi selesai."
```

Berikan izin eksekusi dan jalankan script:
```bash
chmod +x /root/soal1.sh
./root/soal1.sh
```

#### B. Node Tengen (Data Center - Network 4)
Pada node **tengen**, atur IP statis `10.78.4.10/24`, default gateway ke router `10.78.4.1`, nameserver, dan uji konektivitas internet:

```bash
nano /root/soal1.sh
```

```bash
#!/bin/bash
echo "Konfigurasi IP Statis tengen..."
ip addr flush dev eth0
ip addr add 10.78.4.10/24 dev eth0
ip link set eth0 up
ip route add default via 10.78.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf

echo "Test koneksi ke internet:"
ping -c 3 8.8.8.8
```

Eksekusi script:
```bash
chmod +x /root/soal1.sh
./root/soal1.sh
```

#### C. Host di Network 1 (Contoh: Utahime / DNS Server)
Konfigurasi IP statis pada node di Network 1 (contoh: utahime `10.78.1.2/24`):

```bash
nano /root/soal1.sh
```

```bash
#!/bin/bash
ip addr flush dev eth0
ip addr add 10.78.x.x/24 dev eth0
ip link set eth0 up
ip route add default via 10.78.x.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf

echo "Test koneksi ke internet:"
ping -c 3 8.8.8.8
```

Eksekusi script:
```bash
chmod +x /root/soal1.sh
./root/soal1.sh
```

#### D. Host di Network 4 (Contoh: Geto / Load Balancer)
Konfigurasi IP statis pada node di Network 4 (contoh: geto `10.78.4.2/24`):

```bash
nano soal1.sh
```

```bash
#!/bin/bash
# UBAH ANGKA IP DI BAWAH INI SESUAI NAMA HOST
# Contoh: geto=2, maki=3, panda=4, ..., tengen=10
IP_HOST="10.78.4.2"

echo "Konfigurasi IP Statis: $IP_HOST"
ip addr flush dev eth0
ip addr add $IP_HOST/24 dev eth0
ip link set eth0 up
ip route add default via 10.78.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf

echo "Test koneksi ke internet:"
ping -c 3 8.8.8.8
```

Eksekusi script:
```bash
chmod +x soal1.sh
./soal1.sh
```

### Lampiran Bukti dan Pengujian

- **Pengecekan Alamat IP pada Router Jichi:**
  Interface eth0 terhubung ke WAN (NAT) serta eth1 hingga eth4 terpasang IP gateway untuk masing-masing subnet.

  ![IP Address Router Jichi](assets/soal%201%20ip%20a.png)

- **Uji Konektivitas Internet dari Network 1 (Utahime):**
  Host di Network 1 berhasil melakukan ping ke alamat internet (`8.8.8.8`) melalui gateway `10.78.1.1` dan NAT Jichi.

  ![Ping Internet Network 1](assets/soal%201%20n%201.png)

- **Uji Konektivitas Internet dari Network 4 (Geto):**
  Host di Network 4 berhasil melakukan ping ke alamat internet (`8.8.8.8`) melalui gateway `10.78.4.1` dan NAT Jichi.

  ![Ping Internet Network 4](assets/soal%201%20n%204.png)

---

## 2. Konfigurasi DHCP Server pada Tengen

> Tengen, penjaga pusat distribusi di Data Center, harus mengambil alih pengalokasian alamat bagi wilayah yang membutuhkan konfigurasi dinamis. Konfigurasikan isc-dhcp-server pada [PREFIX IP].4.10. Deklarasikan Network 4 ([PREFIX IP].4.0/24) sebagai subnet lokal tanpa pool dinamis, lalu siapkan scope DHCP untuk Network 2 ([PREFIX IP].2.0/24) dan Network 3 ([PREFIX IP].3.0/24). Validasi konfigurasi dan pastikan service aktif tanpa error “No subnet declaration”.

### Langkah Konfigurasi

Pada node **tengen**, install `isc-dhcp-server`, atur antarmuka yang mendengarkan request (`eth0`), dan definisikan konfigurasi subnet pada `/etc/dhcp/dhcpd.conf`:
- Subnet Network 4 dideklarasikan secara kosong (tanpa `range`) agar DHCP server mengetahui jaringan lokal antarmukanya dan terhindar dari pesan galat *"No subnet declaration for eth0"*.
- Subnet Network 2 dan 3 didefinisikan dengan scope DHCP dinamis (`range`, `option routers`, `option domain-name-servers`).

```bash
nano /root/soal2.sh
```

```bash
#!/bin/bash
echo "Memulai konfigurasi DHCP Server pada tengen..."

# 1. Update dan instal DHCP Server
apt-get update
apt-get install -y isc-dhcp-server

# 2. Atur Interface DHCP agar mendengarkan di eth0
echo 'INTERFACESv4="eth0"' > /etc/default/isc-dhcp-server

# 3. Tulis ulang isi dhcpd.conf
cat << 'CONF' > /etc/dhcp/dhcpd.conf
# Konfigurasi Global
default-lease-time 600;
max-lease-time 7200;
authoritative;

# Deklarasi Network 4 (Subnet Lokal tengen)
subnet 10.78.4.0 netmask 255.255.255.0 {
}

# Deklarasi Scope Network 2 (Divisi A)
subnet 10.78.2.0 netmask 255.255.255.0 {
    range 10.78.2.10 10.78.2.100;
    option routers 10.78.2.1;
    option domain-name-servers 192.168.122.1;
}

# Deklarasi Scope Network 3 (Divisi B)
subnet 10.78.3.0 netmask 255.255.255.0 {
    range 10.78.3.10 10.78.3.100;
    option routers 10.78.3.1;
    option domain-name-servers 192.168.122.1;
}
CONF

# 4. Restart layanan dan tampilkan status
service isc-dhcp-server restart
echo "Status isc-dhcp-server:"
service isc-dhcp-server status
```

Eksekusi script:
```bash
chmod +x /root/soal2.sh
./root/soal2.sh
```

### Lampiran Bukti dan Pengujian

- **Status Layanan ISC DHCP Server di Tengen:**
  Layanan `isc-dhcp-server` berhasil dijalankan dengan status `dhcpd is running` tanpa ada galat deklarasi subnet.

  ![Status DHCP Server Tengen](assets/soal%202.png)

---

## 3. Konfigurasi DHCP Relay pada Router Jichi

> Permintaan alamat dari Divisi A dan Divisi B tidak dapat menyeberangi subnet secara langsung. Konfigurasikan jichi sebagai DHCP Relay menuju tengen ([PREFIX IP].4.10), menggunakan eth2 untuk Network 2 dan eth3 untuk Network 3. Buktikan bahwa client dari kedua subnet berhasil memperoleh lease melalui relay.

### Langkah Konfigurasi

#### A. Router Jichi (DHCP Relay)
Pada router **jichi**, pasang `isc-dhcp-relay` dan arahkan ke IP server tengen (`10.78.4.10`) dengan interface pendengar `eth2`, `eth3`, dan `eth4`:

```bash
nano /root/soal3.sh
```

```bash
#!/bin/bash
echo "Memulai konfigurasi DHCP Relay pada jichi..."

# 1. Update dan instal isc-dhcp-relay
apt-get update
apt-get install -y isc-dhcp-relay

# 2. Konfigurasi file default relay
echo 'SERVERS="10.78.4.10"' > /etc/default/isc-dhcp-relay
echo 'INTERFACES="eth2 eth3 eth4"' >> /etc/default/isc-dhcp-relay
echo 'OPTIONS=""' >> /etc/default/isc-dhcp-relay

# 3. Restart layanan relay
service isc-dhcp-relay restart

echo "Status isc-dhcp-relay:"
service isc-dhcp-relay status
```

Eksekusi script:
```bash
chmod +x /root/soal3_jichi.sh
./root/soal3_jichi.sh
```

#### B. Pengecekan pada Client (Network 2 - Contoh: Itadori)
Pada client di Network 2, jalankan script untuk meminta IP via DHCP client (`udhcpc`):

```bash
nano soal3.sh
```

```bash
#!/bin/bash
# Hapus IP yang mungkin tersisa
ip addr flush dev eth0

# Panggil DHCP client bawaan Alpine (udhcpc)
udhcpc -i eth0

# Cek IP yang didapatkan
ip a show eth0
```

Eksekusi script:
```bash
chmod +x soal3.sh
./soal3.sh
```

### Lampiran Bukti dan Pengujian

- **Pengecekan Proses DHCP Relay di Router Jichi:**
  Proses `dhcrelay` aktif meneruskan paket dari interface `eth2`, `eth3`, dan `eth4` ke server `10.78.4.10`.

  ![Proses DHCP Relay Jichi](assets/soal%203%20ps%20aux.png)

- **Alokasi IP Dinamis pada Client Itadori:**
  Client itadori berhasil menerima alokasi IP `10.78.2.14/24` dari server `10.78.4.10` melalui relay Jichi.

  ![IP Address Client Itadori](assets/soal%203%20ip%20a.png)

---

## 4. Multi-Pool DHCP Berdasarkan MAC Address di Network 2 (Divisi A)

> Agar tim Dev dan Support di Divisi A menerima jatah alamat yang berbeda, atur dua pool DHCP pada Network 2. Tetapkan Pool 1 ([PREFIX IP].2.10–[PREFIX IP].2.35) untuk itadori dan fushiguro, serta Pool 2 ([PREFIX IP].2.70–[PREFIX IP].2.95) untuk zenin dan okkotsu. Rentang [PREFIX IP].2.36–[PREFIX IP].2.69 tidak boleh dialokasikan. Karena seluruh client berada pada subnet yang sama, gunakan DHCP class berdasarkan MAC Address atau Client ID untuk memisahkan kedua kelompok.

### Langkah Konfigurasi

#### A. Identifikasi MAC Address Client
Jalankan perintah berikut pada masing-masing client di Divisi A:
```bash
ip link show eth0
```
Hasil MAC Address yang diperoleh:
- **itadori:** `02:42:24:21:1a:00`
- **fushiguro:** `02:42:30:24:4c:00`
- **zenin:** `02:42:28:b9:c0:00`
- **okkotsu:** `02:42:d3:fe:e9:00`

#### B. Konfigurasi Class dan Multi-Pool pada Tengen
Pada node **tengen**, kelompokkan host ke dalam `class "tim-dev"` dan `class "tim-support"` menggunakan subclass hardware ethernet (diawali prefiks tipe hardware `1:`):

```bash
nano /root/soal4.sh
```

```bash
#!/bin/bash
echo "Memulai konfigurasi Multi-Pool DHCP pada tengen..."

cat << 'CONF' > /etc/dhcp/dhcpd.conf
# Konfigurasi Global
default-lease-time 600;
max-lease-time 7200;
authoritative;

# ----------------- KELAS MAC ADDRESS -----------------
# Kelas untuk Tim Dev (itadori, fushiguro)
class "tim-dev" {
    match hardware;
}
# UBAH MAC ADDRESS DI BAWAH INI (biarkan angka 1: di depannya)
subclass "tim-dev" 1:02:42:24:21:1a:00; # MAC itadori
subclass "tim-dev" 1:02:42:30:24:4c:00; # MAC fushiguro

# Kelas untuk Tim Support (zenin, okkotsu)
class "tim-support" {
    match hardware;
}
# UBAH MAC ADDRESS DI BAWAH INI (biarkan angka 1: di depannya)
subclass "tim-support" 1:02:42:28:b9:c0:00; # MAC zenin
subclass "tim-support" 1:02:42:d3:fe:e9:00; # MAC okkotsu

# ----------------- DEKLARASI SUBNET -----------------
# Deklarasi Network 4 (Subnet Lokal tengen)
subnet 10.78.4.0 netmask 255.255.255.0 {
}

# Deklarasi Scope Network 2 (Divisi A) dengan Multi-Pool
subnet 10.78.2.0 netmask 255.255.255.0 {
    option routers 10.78.2.1;
    option domain-name-servers 192.168.122.1;

    # Pool 1: Khusus untuk member kelas "tim-dev"
    pool {
        allow members of "tim-dev";
        range 10.78.2.10 10.78.2.35;
    }

    # Pool 2: Khusus untuk member kelas "tim-support"
    pool {
        allow members of "tim-support";
        range 10.78.2.70 10.78.2.95;
    }
}

# Deklarasi Scope Network 3 (Divisi B)
subnet 10.78.3.0 netmask 255.255.255.0 {
    range 10.78.3.10 10.78.3.100;
    option routers 10.78.3.1;
    option domain-name-servers 192.168.122.1;
}
CONF

# Restart layanan
service isc-dhcp-server restart
echo "Status isc-dhcp-server:"
service isc-dhcp-server status
```

Eksekusi script:
```bash
chmod +x /root/soal4.sh
./root/soal4.sh
```

### Lampiran Bukti dan Pengujian

- **Alokasi IP Tim Dev (Fushiguro - Pool 1):**
  Fushiguro mendapatkan IP `10.78.2.15/24` yang berada dalam rentang Pool 1 (`10.78.2.10`–`10.78.2.35`).

  ![IP Client Fushiguro Pool 1](assets/soal%204%20a.png)

- **Alokasi IP Tim Support (Zenin - Pool 2):**
  Zenin mendapatkan IP `10.78.2.71/24` yang berada dalam rentang Pool 2 (`10.78.2.70`–`10.78.2.95`), memisahkan rentang IP tanpa alokasi pada `10.78.2.36`–`10.78.2.69`.

  ![IP Client Zenin Pool 2](assets/soal%204%20b.png)

---

## 5. Konfigurasi Lease Time dan DHCP Options pada Network 3 (Divisi B)

> Setiap tim lapangan memiliki durasi operasi yang berbeda. Pada Network 3, berikan short lease 30 menit (1800 detik) kepada ino dan kusakabe, serta long lease 12 jam (43200 detik) kepada miwa. Gunakan pool short lease [PREFIX IP].3.10–[PREFIX IP].3.89 dan pool long lease [PREFIX IP].3.100–[PREFIX IP].3.199. Sesuaikan default-lease-time dan max-lease-time untuk setiap kelas client. Berikan pula DHCP options berupa DNS [PREFIX IP].1.2 dan [PREFIX IP].1.3, serta domain-search <xxxx>.com.

### Langkah Konfigurasi

#### A. Identifikasi MAC Address Client Divisi B
Cek MAC address pada masing-masing client di Network 3:
```bash
ip link show eth0
```
- **ino:** `02:42:8a:f1:0f:00`
- **kusakabe:** `02:42:a5:de:b3:00`
- **miwa:** `02:42:80:41:bf:00`

#### B. Konfigurasi DHCP Server pada Tengen
Definisikan class `short-lease` dan `long-lease` serta atur DHCP Options khusus untuk subnet Network 3 (`domain-name-servers 10.78.1.2, 10.78.1.3` dan `domain-name "k29.com"`):

```bash
nano /root/soal5.sh
```

```bash
#!/bin/bash
echo "Memulai konfigurasi Lease Time dan Options pada tengen..."

cat << 'CONF' > /etc/dhcp/dhcpd.conf
# Konfigurasi Global
default-lease-time 600;
max-lease-time 7200;
authoritative;

# ----------------- KELAS NETWORK 2 (Soal 4) -----------------
class "tim-dev" { match hardware; }
subclass "tim-dev" 1:02:42:24:21:1a:00; # MAC itadori
subclass "tim-dev" 1:02:42:30:24:4c:00; # MAC fushiguro

class "tim-support" { match hardware; }
subclass "tim-support" 1:02:42:28:b9:c0:00; # MAC zenin
subclass "tim-support" 1:02:42:d3:fe:e9:00; # MAC okkotsu

# ----------------- KELAS NETWORK 3 (Soal 5) -----------------
class "short-lease" { match hardware; }
subclass "short-lease" 1:02:42:8a:f1:0f:00; # MAC ino
subclass "short-lease" 1:02:42:a5:de:b3:00; # MAC kusakabe

class "long-lease" { match hardware; }
subclass "long-lease" 1:02:42:80:41:bf:00; # MAC miwa

# ----------------- DEKLARASI SUBNET -----------------
# Deklarasi Network 4
subnet 10.78.4.0 netmask 255.255.255.0 {
}

# Deklarasi Network 2 (Divisi A)
subnet 10.78.2.0 netmask 255.255.255.0 {
    option routers 10.78.2.1;
    option domain-name-servers 192.168.122.1;

    pool {
        allow members of "tim-dev";
        range 10.78.2.10 10.78.2.35;
    }
    pool {
        allow members of "tim-support";
        range 10.78.2.70 10.78.2.95;
    }
}

# Deklarasi Network 3 (Divisi B)
subnet 10.78.3.0 netmask 255.255.255.0 {
    option routers 10.78.3.1;

    # DHCP Options Spesifik Network 3
    option domain-name-servers 10.78.1.2, 10.78.1.3;
    option domain-name "k29.com";

    # Pool 1: Short Lease (30 menit = 1800 detik)
    pool {
        allow members of "short-lease";
        range 10.78.3.10 10.78.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Pool 2: Long Lease (12 jam = 43200 detik)
    pool {
        allow members of "long-lease";
        range 10.78.3.100 10.78.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }
}
CONF

# Restart layanan DHCP Server
service isc-dhcp-server restart
echo "Status isc-dhcp-server:"
service isc-dhcp-server status
```

Eksekusi script:
```bash
chmod +x /root/soal5_tengen.sh
./root/soal5_tengen.sh
```

#### C. Uji Renew dan Verifikasi di Client Network 3
Jalankan pembaharuan IP pada client Network 3:
```bash
ip addr flush dev eth0
udhcpc -i eth0
cat /etc/resolv.conf
```

### Lampiran Bukti dan Pengujian

- **Alokasi IP Short-Lease (Ino):**
  Client Ino memperoleh IP `10.78.3.14/24` yang berada di dalam range short-lease (`10.78.3.10`–`10.78.3.89`).

  ![IP Client Ino Short Lease](assets/soal%205%20a.png)

- **Alokasi IP Long-Lease (Miwa):**
  Client Miwa memperoleh IP `10.78.3.100/24` yang berada di dalam range long-lease (`10.78.3.100`–`10.78.3.199`).

  ![IP Client Miwa Long Lease](assets/soal%205%20b.png)

---

## 6. Konfigurasi Static Lease (Fixed Address) untuk Personel VIP Kugisaki

> Kugisaki ditetapkan sebagai personel VIP yang harus mempertahankan alamat yang sama setiap kali terhubung. Buat DHCP static lease berdasarkan MAC Address client tersebut dengan fixed address [PREFIX IP].3.99. Pastikan alamat ini berada di luar seluruh pool dinamis, validasi konfigurasi server, lalu renew lease pada client. Buktikan bahwa alamat yang diterima sesuai dengan reservasi.

### Langkah Konfigurasi

#### A. Identifikasi MAC Address Kugisaki
Periksa MAC Address interface `eth0` pada client kugisaki:
```bash
ip link show eth0
```
Didapatkan MAC Address: `02:42:8f:4e:be:00`.

#### B. Konfigurasi Host Reservation pada Tengen
Tambahkan blok reservasi host `kugisaki` pada `/etc/dhcp/dhcpd.conf` dengan alamat tetap `10.78.3.99` (berada di luar pool dinamis `10.78.3.10`–`10.78.3.89` dan `10.78.3.100`–`10.78.3.199`):

```bash
nano soal6.sh
```

```bash
#!/bin/bash
echo "Memulai konfigurasi Lease Time dan Options pada tengen..."

cat << 'CONF' > /etc/dhcp/dhcpd.conf
# Konfigurasi Global
default-lease-time 600;
max-lease-time 7200;
authoritative;

# ----------------- KELAS NETWORK 2 (Soal 4) -----------------
class "tim-dev" { match hardware; }
subclass "tim-dev" 1:02:42:24:21:1a:00; # MAC itadori
subclass "tim-dev" 1:02:42:30:24:4c:00; # MAC fushiguro

class "tim-support" { match hardware; }
subclass "tim-support" 1:02:42:28:b9:c0:00; # MAC zenin
subclass "tim-support" 1:02:42:d3:fe:e9:00; # MAC okkotsu

# ----------------- KELAS NETWORK 3 (Soal 5) -----------------
class "short-lease" { match hardware; }
subclass "short-lease" 1:02:42:8a:f1:0f:00; # MAC ino
subclass "short-lease" 1:02:42:a5:de:b3:00; # MAC kusakabe

class "long-lease" { match hardware; }
subclass "long-lease" 1:02:42:80:41:bf:00; # MAC miwa

# ----------------- DEKLARASI SUBNET -----------------
# Deklarasi Network 4
subnet 10.78.4.0 netmask 255.255.255.0 {
}

# Deklarasi Network 2 (Divisi A)
subnet 10.78.2.0 netmask 255.255.255.0 {
    option routers 10.78.2.1;
    option domain-name-servers 192.168.122.1;

    pool {
        allow members of "tim-dev";
        range 10.78.2.10 10.78.2.35;
    }
    pool {
        allow members of "tim-support";
        range 10.78.2.70 10.78.2.95;
    }
}

# Deklarasi Network 3 (Divisi B)
subnet 10.78.3.0 netmask 255.255.255.0 {
    option routers 10.78.3.1;

    # DHCP Options Spesifik Network 3
    option domain-name-servers 10.78.1.2, 10.78.1.3;
    option domain-name "k29.com";

    # Pool 1: Short Lease (30 menit = 1800 detik)
    pool {
        allow members of "short-lease";
        range 10.78.3.10 10.78.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Pool 2: Long Lease (12 jam = 43200 detik)
    pool {
        allow members of "long-lease";
        range 10.78.3.100 10.78.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }
}

# Reservasi IP VIP Kugisaki (Soal 6)
host kugisaki {
    hardware ethernet 02:42:8f:4e:be:00; # Ganti dengan MAC Address Kugisaki
    fixed-address 10.78.3.99;
}
CONF

# Restart layanan DHCP Server
service isc-dhcp-server restart
echo "Status isc-dhcp-server:"
service isc-dhcp-server status
```

#### C. Renew Lease pada Kugisaki
Pada terminal kugisaki, perbarui alokasi IP:
```bash
./soal3.sh
```

### Lampiran Bukti dan Pengujian

- **Hasil Alokasi IP Reservasi Kugisaki:**
  Kugisaki berhasil mendapatkan alokasi tetap `10.78.3.99/24` sesuai reservasi MAC Address-nya.

  ![Static Lease Kugisaki](assets/soal%206.png)

---

## 7. Validasi Konfigurasi Jaringan Client dan Database Lease DHCP

> Setelah aturan alokasi diterapkan, pastikan setiap client menerima konfigurasi jaringan sesuai wilayahnya: subnet mask 255.255.255.0 (/24), gateway dan broadcast address yang benar, DNS [PREFIX IP].1.2 serta [PREFIX IP].1.3, dan domain-search yang ditentukan. Periksa IP address dan routing seluruh client Divisi A dan Divisi B, kemudian cocokkan lease dengan /var/lib/dhcp/dhcpd.leases pada tengen. Pastikan tidak ada alamat yang bertabrakan atau berada di luar kebijakan pool.

### Langkah Validasi

#### A. Validasi di Sisi Client (Contoh: Itadori, Zenin, Ino, Miwa)
Buat script validasi `soal7.sh` untuk memeriksa IP, subnet mask, tabel routing gateway, dan nameserver:

```bash
nano soal7.sh
```

```bash
#!/bin/bash
echo "=== VALIDASI KONFIGURASI JARINGAN CLIENT (SOAL 7) ==="

echo -e "\n1. IP Address, Subnet Mask (/24), dan Broadcast:"
ip a show eth0

echo -e "\n2. Tabel Routing (Default Gateway):"
ip route

echo -e "\n3. Konfigurasi DNS Server dan Domain:"
cat /etc/resolv.conf

echo -e "\n=== VALIDASI SELESAI ==="
```

Jalankan script:
```bash
chmod +x soal7.sh
./soal7.sh
```

#### B. Validasi Database Lease pada Tengen
Pada node **tengen**, periksa database lease aktif `/var/lib/dhcp/dhcpd.leases`:

```bash
nano /root/soal7.sh
```

```bash
#!/bin/bash
echo "=== VALIDASI DATABASE LEASE DHCP SERVER (SOAL 7) ==="

echo -e "\nMenampilkan daftar IP dinamis yang telah disewakan:"
cat /var/lib/dhcp/dhcpd.leases | grep -E "lease|binding state|hardware ethernet"

echo -e "\n=== VALIDASI SELESAI ==="
echo "Catatan: IP 10.78.3.99 milik Kugisaki tidak akan muncul di sini karena menggunakan static lease."
```

Jalankan script:
```bash
chmod +x /root/soal7.sh
./root/soal7.sh
```

### Lampiran Bukti dan Pengujian

- **Validasi Konfigurasi pada Client (Itadori):**
  Client memiliki IP `10.78.2.14/24`, default gateway `10.78.2.1`, serta nameserver yang valid.

  ![Validasi Client Itadori](assets/soal%207%20clien.png)

- **Database Lease Server Tengen (Bagian 1):**
  Daftar lease dinamis tercatat pada `/var/lib/dhcp/dhcpd.leases`.

  ![Database Lease Tengen 1](assets/soal%207%20tengen%20a.png)

- **Database Lease Server Tengen (Bagian 2):**
  Seluruh client tercatat dengan status `binding state active`, tidak ada tabrakan IP, dan IP static Kugisaki tidak masuk ke leases dinamis.

  ![Database Lease Tengen 2](assets/soal%207%20tengen%20b.png)

---

## 8. Analisis Protokol DORA (Packet Capture via tcpdump & Wireshark)

> Sebelum Curtain dibuka kembali, buktikan bahwa proses pemberian alamat berjalan sesuai protokol. Lakukan packet capture saat salah satu client Network 2 atau Network 3 meminta lease baru. Gunakan tcpdump pada tengen atau jalur menuju Data Center untuk menunjukkan urutan DHCPDISCOVER → DHCPOFFER → DHCPREQUEST → DHCPACK. Identifikasi alamat server, alamat yang diberikan, lease time, dan field giaddr. Pastikan nilai giaddr sesuai dengan interface jichi yang menerima request dari subnet client.

### Langkah Analisis dan Packet Capture

#### A. Menjalankan Capture pada Node Tengen
Pada node **tengen**, buat script `soal8.sh` untuk menangkap paket DHCP (port UDP 67 & 68) dengan opsi verbose `-vvv`:

```bash
nano soal8.sh
```

```bash
#!/bin/bash
echo "=== PACKET CAPTURE PROTOKOL DORA DHCP (SOAL 8) ==="

# Instal tcpdump jika belum ada
apt-get update
apt-get install -y tcpdump

echo -e "\n[MENUNGGU PAKET DHCP...]"
echo "Buka terminal client (misal: itadori di Divisi A atau ino di Divisi B)."
echo "Jalankan perintah ini di client: ip addr flush dev eth0 && udhcpc -i eth0"
echo -e "Tekan Ctrl+C di sini untuk berhenti jika client sudah dapat IP.\n"
echo "------------------------------------------------------------------"

# Menjalankan tcpdump pada port 67 dan 68 (port standar DHCP) dengan output detail (-vvv)
tcpdump -i eth0 -n -vvv port 67 or port 68
```

Jalankan script:
```bash
chmod +x /root/soal8_tengen.sh
./root/soal8_tengen.sh
```

#### B. Meminta Lease Baru pada Client
Pada node client (contoh: itadori), jalankan pembersihan IP dan permintaan lease baru:
```bash
ip addr flush dev eth0 && udhcpc -i eth0
```

### Analisis Hasil Capture Protokol DORA

1. **DHCPDISCOVER:** Client mengirimkan paket broadcast pencarian DHCP server melalui relay agent Jichi.
2. **DHCPOFFER:** Server Tengen (`10.78.4.10`) menawarkan alamat IP `10.78.2.14` kepada relay agent (`10.78.2.1`).
3. **DHCPREQUEST:** Client menyetujui dan meminta alokasi alamat IP `10.78.2.14` kepada DHCP server `10.78.4.10`.
4. **DHCPACK:** Server Tengen mengonfirmasi dan memberikan hak sewa (lease) IP address kepada client.
- **DHCP Server Identifier:** `10.78.4.10`
- **Your (Client) IP Address:** `10.78.2.14`
- **Lease Time:** 483 detik (default 600s)
- **Field `giaddr` (Gateway IP / Relay Agent IP Address):** `10.78.2.1` (sesuai dengan IP antarmuka `eth2` Router Jichi di Network 2 yang meneruskan request client).

### Lampiran Bukti dan Pengujian

- **Terminal Capture DHCP Discover & Offer (Tengen):**
  Tangkap paket menunjukkan masuknya pesan DHCP Discover dengan Gateway-IP `10.78.2.1` dan balasan DHCPOFFER dengan tawaran IP `10.78.2.14`.

  ![Terminal Capture Discover & Offer](assets/soal%208%20a.png)

- **Terminal Capture DHCP Request & ACK (Tengen):**
  Tangkap paket menunjukkan pesan DHCP Request dan konfirmasi DHCP ACK beserta parameter jaringan lengkap.

  ![Terminal Capture Request & ACK](assets/soal%208%20b.png)

- **Urutan 4 Langkah Protokol DORA (Wireshark):**
  Tampilan Wireshark membuktikan alur sekuensial lengkap: DHCP Discover -> DHCP Offer -> DHCP Request -> DHCP ACK.

  ![Protokol DORA Wireshark](assets/soal%208%20DORA.png)

- **Identifikasi Field `giaddr` (Relay Agent IP Address):**
  Detail packet header membuktikan field `giaddr` bernilai `10.78.2.1` (IP interface Jichi).

  ![Field giaddr](assets/soal%208%20giaddr.png)

- **Identifikasi Server Identifier & Lease Time:**
  Detail Option 54 (Server Identifier: `10.78.4.10`) dan Option 51 (IP Address Lease Time).

  ![Server ID & Lease Time](assets/soal%208%20alamat%20server%20dan%20lease%20time.png)

---

## 9. Simulasi Pemutusan dan Pemulihan DHCP Relay pada Jichi

> Sebuah gangguan memutus jalur relay dan membuat permintaan alamat tidak sampai ke Data Center. Hentikan service DHCP Relay pada jichi, lalu paksa salah satu client di Network 2 atau Network 3 meminta lease baru dan catat gejalanya. Pulihkan service relay, ulangi permintaan DHCP, lalu buktikan bahwa client kembali memperoleh alamat dari pool yang benar dengan gateway semula.

### Langkah Simulasi Gangguan dan Pemulihan

#### A. Menghentikan Layanan DHCP Relay pada Jichi
Simulasikan gangguan dengan mematikan service `isc-dhcp-relay`:
```bash
service isc-dhcp-relay stop
ps aux | grep dhcrelay
```

#### B. Menguji Dampak pada Client (Itadori)
Paksa client meminta lease baru:
```bash
ip addr flush dev eth0
udhcpc -i eth0
```
**Gejala:** Client mengirimkan paket broadcast `discover` berulang kali, namun tidak ada respons dari DHCP server karena jalur relay mati. Setelah timeout, muncul pesan `udhcpc failed to get a DHCP lease`.

#### C. Pemulihan Layanan DHCP Relay pada Jichi
Nyalakan kembali service relay:
```bash
service isc-dhcp-relay start
```

#### D. Meminta Ulang Lease pada Client
Ulangi request DHCP pada client:
```bash
udhcpc -i eth0
ip a show eth0
ip route
```
**Hasil:** Client langsung berhasil memperoleh IP `10.78.2.14` dari pool yang sesuai beserta default route gateway `10.78.2.1`.

### Lampiran Bukti dan Pengujian

- **Gejala Kegagalan Saat DHCP Relay Mati:**
  Client itadori gagal memperoleh IP dan menghasilkan error `udhcpc failed to get a DHCP lease`.

  ![Gejala Error Saat Relay Mati](assets/soal%209%20error.png)

- **Pemulihan Konektivitas Setelah DHCP Relay Aktif:**
  Setelah service relay dinyalakan kembali, client itadori sukses memperoleh IP `10.78.2.14` dan default gateway `10.78.2.1`.

  ![Pemulihan Relay Berhasil](assets/soal%209%20fix.png)

---

## 10. Konfigurasi Autostart / Persistensi Layanan Pasca Reboot

> Setelah gangguan Shibuya tertangani, pastikan pemulihan bertahan setelah restart. Aktifkan autostart DHCP Server pada tengen dan DHCP Relay pada jichi, lalu restart kedua node. Verifikasi status layanan, IP, gateway, lease, dan konektivitas client Network 2–3. Pastikan kebijakan Pool 1, Pool 2, short lease, long lease, dan fixed address tetap berlaku.

### Langkah Konfigurasi Autostart

#### A. Autostart DHCP Server pada Tengen
Tambahkan perintah startup ke `/root/.bashrc` (atau aktifkan via systemctl jika didukung):
```bash
echo "service isc-dhcp-server start" >> /root/.bashrc
systemctl enable isc-dhcp-server
```

#### B. Autostart Konfigurasi IP & DHCP Relay pada Jichi
Tambahkan pemanggilan script inisialisasi jaringan dan relay ke `/root/.bashrc`:
```bash
echo "/root/soal1.sh" >> /root/.bashrc
echo "service isc-dhcp-relay start" >> /root/.bashrc
```

#### C. Reboot dan Verifikasi Kedua Node
Restart kedua node (`reboot`), lalu verifikasi bahwa seluruh layanan menyala secara otomatis.

### Lampiran Bukti dan Pengujian

- **Verifikasi Status Layanan Otomatis Pasca-Reboot:**
  Router Jichi otomatis menjalankan konfigurasi interface dan relay, serta Tengen otomatis menjalankan `dhcpd` (`isc-dhcp-server is running`).

  ![Verifikasi Layanan Pasca Reboot](assets/soal%2010%20reboot.png)

- **Verifikasi Kebijakan Lease Seluruh Kategori Client:**
  - Client Dev (Itadori): Mendapatkan IP Pool 1 `10.78.2.14`
  - Client Short Lease (Ino): Mendapatkan IP `10.78.3.14` (lease 1800 detik)
  - Client VIP (Kugisaki): Tetap mendapatkan fixed address `10.78.3.99`

  ![Pengecekan Alokasi IP Client](assets/soal%2010%20ip%20check.png)

- **Verifikasi Konektivitas Client (Ping Server & Internet):**
  Client itadori berhasil melakukan ping ke server DHCP tengen (`10.78.4.10`) dan ping ke internet (`8.8.8.8`) tanpa packet loss.

  ![Ping Check Pasca Reboot](assets/soal%2010%20ping%20check.png)

---

## 11. Konfigurasi DNS Master (Utahime) & DNS Slave (Shoko) serta Sinkronisasi Zona

> Utahime dan Shoko ditugaskan membangun sistem penamaan domain resmi agar seluruh pos tidak perlu menghafal alamat IP mentah. Konfigurasikan BIND9 pada utahime sebagai DNS Master dan shoko sebagai DNS Slave untuk mengelola domain jujutsu.<xxxx>.com. Atur SOA record, NS delegasi untuk kedua server, dan terapkan allow-transfer dari Master ke Slave. Pastikan file zona berhasil tersinkronisasi otomatis ke shoko saat nomor serial di utahime dinaikkan, lalu buktikan dengan melakukan query dig ke kedua server dari salah satu client.

### Langkah Konfigurasi

#### A. Konfigurasi DNS Master pada Utahime
Pada node **utahime**, buat script konfigurasi `/root/soal11.sh`:

```bash
nano /root/soal11.sh
```

```bash
#!/bin/bash
echo "Konfigurasi DNS Master (utahime)..."

apt-get update
apt-get install -y bind9 bind9utils

# Konfigurasi zona master dan allow-transfer ke IP shoko
cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k29.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.k29.com";
    allow-transfer { 10.78.1.3; };
};
EOF

# Membuat direktori dan file zona
mkdir -p /etc/bind/jujutsu
cat << 'EOF' > /etc/bind/jujutsu/jujutsu.k29.com
$TTL 604800
@   IN  SOA utahime.jujutsu.k29.com. root.jujutsu.k29.com. (
            2026101501 ; Serial
            604800     ; Refresh
            86400      ; Retry
            2419200    ; Expire
            604800 )   ; Negative Cache TTL
;
@       IN  NS  utahime.jujutsu.k29.com.
@       IN  NS  shoko.jujutsu.k29.com.
utahime IN  A   10.78.1.2
shoko   IN  A   10.78.1.3
EOF

# Menjalankan layanan menggunakan nama 'named'
service named restart

echo "Status Layanan DNS Master:"
ps aux | grep named | grep -v grep
```

Eksekusi script:
```bash
chmod +x /root/soal11_master.sh
./root/soal11_master.sh
```

#### B. Konfigurasi DNS Slave pada Shoko
Pada node **shoko**, buat script konfigurasi `/root/soal11.sh`:

```bash
nano /root/soal11.sh
```

```bash
#!/bin/bash
echo "Konfigurasi DNS Slave (shoko)..."

apt-get update
apt-get install -y bind9 bind9utils

# Konfigurasi zona slave yang menunjuk ke IP utahime
cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k29.com" {
    type slave;
    masters { 10.78.1.2; };
    file "/var/lib/bind/jujutsu.k29.com";
};
EOF

# Menjalankan layanan menggunakan nama 'named'
service named restart

echo "Status Layanan DNS Slave:"
ps aux | grep named | grep -v grep
```

Eksekusi script:
```bash
chmod +x /root/soal11_slave.sh
./root/soal11_slave.sh
```

#### C. Pengujian Sinkronisasi Zona (Zone Transfer)
1. Pada **utahime**, edit file zona `/etc/bind/jujutsu/jujutsu.k29.com` dan naikkan Serial dari `2026101501` menjadi `2026101502`.
2. Muat ulang layanan:
   ```bash
   service named restart
   # atau: service bind9 reload
   ```
3. Pada **shoko**, periksa bahwa data zona terbaru berhasil ditransfer:
   ```bash
   cat /var/lib/bind/jujutsu.k29.com
   ```

#### D. Pengujian Query DNS dari Client (Itadori)
Pasang `bind-tools` di Alpine client lalu jalankan query `dig`:
```bash
apk update
apk add bind-tools

# Uji query ke DNS Master:
dig @10.78.1.2 NS jujutsu.k29.com

# Uji query ke DNS Slave:
dig @10.78.1.3 NS jujutsu.k29.com
```

### Lampiran Bukti dan Pengujian

- **Bukti Sinkronisasi Master-Slave (File Zona pada Shoko):**
  File `/var/lib/bind/jujutsu.k29.com` pada Shoko terisi data zona hasil replikasi dari master Utahime.

  ![Sinkronisasi Zona Master Slave](assets/soal%2011%20bukti%20master%20slave%20berhubungan.png)

- **Uji Query DNS ke Master (Utahime):**
  Query `dig @10.78.1.2 NS jujutsu.k29.com` dijawab dengan status `NOERROR` beserta data NS kedua server.

  ![Query dig Master](assets/soal%2011%20dig%20master.png)

- **Uji Query DNS ke Slave (Shoko):**
  Query `dig @10.78.1.3 NS jujutsu.k29.com` ke server slave Shoko.

  ![Query dig Slave](assets/soal%2011%20dig%20slave.png)

---

## 12. Konfigurasi A Record, CNAME, Reverse DNS (PTR), dan DNS Forwarder

> Peta domain harus memetakan pintu masuk utama dan tetap bisa mencari alamat di luar kawasan Shibuya. Pada utahime, buat A record jujutsu.<xxxx>.com yang mengarah ke gojo, serta CNAME www yang merujuk ke domain utama tersebut. Buat pula Reverse DNS (zona PTR) untuk melacak IP gojo kembali ke domain resminya, dan aktifkan fitur DNS Forwarder pada BIND9 mengarah ke IP gateway internet (192.168.122.1). Uji dari client dengan dig untuk mengecek CNAME, PTR, dan buktikan client tetap bisa melakukan ping ke domain internet seperti google.com.

### Langkah Konfigurasi

Pada node DNS Master (**utahime**), buat script konfigurasi `/root/soal12.sh`:

```bash
nano /root/soal12.sh
```

```bash
#!/bin/bash
echo "Menambahkan A Record, CNAME, PTR, dan Forwarder di utahime..."

# Asumsi IP Gojo (UBAH JIKA BERBEDA)
IP_GOJO="10.78.1.4"
OCTET_TERAKHIR="4" # Angka terakhir dari IP Gojo (dari 10.78.1.4)

# 1. Menambahkan Forwarder ke 192.168.122.1
cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";

    forwarders {
        192.168.122.1;
    };

    allow-query { any; };
    dnssec-validation no;
    listen-on-v6 { any; };
};
EOF

# 2. Update File Zona Forward (Menambahkan A record Gojo & CNAME www)
# Perhatikan Serial dinaikkan menjadi 2026101503
cat << 'EOF' > /etc/bind/jujutsu/jujutsu.k29.com
$TTL 604800
@   IN  SOA utahime.jujutsu.k29.com. root.jujutsu.k29.com. (
            2026101503 ; Serial
            604800     ; Refresh
            86400      ; Retry
            2419200    ; Expire
            604800 )   ; Negative Cache TTL
;
@       IN  NS      utahime.jujutsu.k29.com.
@       IN  NS      shoko.jujutsu.k29.com.
@       IN  A       10.78.1.4
www     IN  CNAME   jujutsu.k29.com.
gojo    IN  A       10.78.1.4
utahime IN  A       10.78.1.2
shoko   IN  A       10.78.1.3
EOF

# 3. Mendaftarkan Zona Reverse di named.conf.local
# Jika IP Gojo 10.78.1.4, maka zona reverse-nya adalah 1.78.10.in-addr.arpa
cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k29.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.k29.com";
    allow-transfer { 10.78.1.3; };
};

zone "1.78.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jujutsu/10.78.1.rev";
};
EOF

# 4. Membuat File Zona Reverse (PTR)
cat << 'EOF' > /etc/bind/jujutsu/10.78.1.rev
$TTL 604800
@   IN  SOA utahime.jujutsu.k29.com. root.jujutsu.k29.com. (
            2026101501 ; Serial
            604800     ; Refresh
            86400      ; Retry
            2419200    ; Expire
            604800 )   ; Negative Cache TTL
;
@   IN  NS  utahime.jujutsu.k29.com.
@   IN  NS  shoko.jujutsu.k29.com.
4   IN  PTR jujutsu.k29.com.
EOF

# Restart Layanan BIND9 (named)
service named restart

echo "Konfigurasi Soal 12 Selesai. Status BIND9:"
service named status
```

Eksekusi script:
```bash
chmod +x /root/soal12.sh
./root/soal12.sh
```

### Langkah Pengujian dan Verifikasi dari Client / Terminal

Jalankan perintah pengujian berikut:

```bash
# a. Menguji CNAME
dig @10.78.1.2 www.jujutsu.k29.com

# b. Menguji Reverse DNS (PTR)
dig @10.78.1.2 -x 10.78.1.4

# c. Menguji DNS Forwarder
dig @10.78.1.2 google.com

# d. Menguji Konektivitas Ping ke Domain Publik
ping -c 3 google.com
```

### Lampiran Bukti dan Pengujian

- **Uji Query CNAME (`www.jujutsu.k29.com`):**
  Query mengembalikan CNAME `jujutsu.k29.com.` yang merujuk ke IP `10.78.1.4`.

  ![Query CNAME](assets/soal%2012%20CNAME.png)

- **Uji Query Reverse DNS / PTR (`10.78.1.4`):**
  Query reverse `dig -x 10.78.1.4` mengembalikan record `4.1.78.10.in-addr.arpa.` yang mengarah ke `jujutsu.k29.com.`.

  ![Query PTR Reverse DNS](assets/soal%2012%20PTR.png)

- **Uji DNS Forwarder (`google.com`):**
  BIND9 berhasil mem-forward query domain internet publik ke gateway `192.168.122.1` dan mengembalikan daftar IP server Google.

  ![Query DNS Forwarder](assets/soal%2012%20forwarder.png)

- **Uji Ping Domain Internet (`google.com`):**
  Ping ke domain `google.com` berhasil diselesaikan dan dijawab dengan 0% packet loss.

  ![Ping Domain Google](assets/soal%2012%20ping%20domain%20google.png)

---

13. Kepala Sekolah Yaga dan Inumaki mendirikan database terpusat yang redundan agar log aktivitas kutukan tetap aman tersimpan. Konfigurasikan MariaDB pada yaga sebagai DB-Master dan inumaki sebagai DB-Slave. Buat database db_shibuya_<xxxx> beserta tabel request_logs di Master, aktifkan binary logging (log-bin, server-id), lalu hubungkan inumaki sebagai Slave yang menyalin data secara realtime dengan CHANGE MASTER TO. Berikan hak akses remote bagi seluruh node di Network 4, lalu buktikan replikasi berhasil dengan memasukkan data baru di Master dan memeriksa hasilnya di Slave.
14. Para penyihir lapangan bersiaga di Data Center sebagai pekerja backend untuk memproses aplikasi. Pasang Nginx dan PHP-FPM pada maki dan panda untuk menyajikan web frontend yang menampilkan hostname masing-masing. Pada nanami, todo, dan kirara, siapkan layanan API yang mencatat log request ke database yaga. Konfigurasikan virtual host agar worker merespons domain layanan yang ditentukan. Batasi akses langsung dari klien ke worker, web worker hanya menerima trafik melalui jalur proxy web yang ditentukan, sedangkan worker API hanya menerima trafik melalui geto. Uji bahwa akses langsung dari klien ditolak, sementara akses melalui reverse proxy tetap berhasil.
15. Geto bertugas mengendalikan pembagian beban request API di internal Data Center agar server tidak tumbang bersamaan. Konfigurasikan Nginx pada geto sebagai Load Balancer internal dengan upstream api_cluster yang mengarahkan trafik ke nanami dan todo. Terapkan algoritma Weighted Round Robin dengan bobot 3:1, di mana nanami menerima porsi beban tiga kali lebih banyak daripada todo. Buktikan distribusi beban ini dengan melakukan loop request berulang kali ke geto dari jaringan lokal Data Center dan periksa rasio responnya.
16. Gojo berdiri di perbatasan DMZ sebagai gerbang publik tunggal bagi seluruh client dari luar maupun dalam. Konfigurasikan Nginx pada gojo untuk melayani domain jujutsu.<xxxx>.com dan www.jujutsu.<xxxx>.com menggunakan metode Path-Based Routing. Atur agar request root (/) diteruskan secara Round Robin ke worker frontend (maki dan panda), sedangkan request ke path /api diteruskan langsung ke geto. Uji dari client Divisi A atau B bahwa akses ke web utama dibalas oleh Maki/Panda, sedangkan akses ke /api diteruskan dan dijawab oleh Nanami/Todo.
17. Komando pusat perlu mengetahui IP asli klien yang mengirimkan request tanpa tertukar dengan IP proxy perantara. Konfigurasikan gojo dan geto agar meneruskan informasi alamat klien melalui header X-Real-IP dan X-Forwarded-For. Pastikan geto hanya mempercayai informasi alamat klien yang diterima dari proxy terpercaya, dan skrip API menyimpan alamat klien yang telah diverifikasi ke kolom client_ip pada tabel request_logs di database yaga. Uji dengan mengirimkan request dari klien Network 2 dan Network 3 ke endpoint /api, kemudian periksa database untuk memastikan alamat yang tercatat sesuai dengan IP klien asal, bukan IP gojo atau geto.
18. nanami dan todo merupakan worker API utama, sedangkan kirara disiapkan sebagai worker cadangan. Konfigurasikan upstream api_cluster pada geto agar kirara menjadi server backup, serta terapkan passive health check dengan parameter max_fails=2 dan fail_timeout=5s pada worker API utama. Pastikan kirara menjalankan layanan API yang kompatibel dengan endpoint utama. Simulasikan gangguan dengan menghentikan layanan Nginx atau layanan API pada nanami dan todo. Buktikan dari klien bahwa request ke /api dialihkan ke kirara dan menghasilkan respons API yang valid tanpa error 502 Bad Gateway.
19. gojo bertugas mengoptimalkan layanan web sekaligus membatasi request berlebihan. Konfigurasikan Nginx Proxy Caching untuk halaman web frontend dengan masa berlaku cache 10 menit dan tambahkan header X-Cache-Status. Terapkan rate limiting pada path /api dengan batas 10 request per detik per IP klien. Buktikan bahwa request ke halaman web yang memenuhi syarat cache menghasilkan status MISS pada akses awal dan HIT pada akses berikutnya. Uji rate limiting secara terpisah dengan mengirimkan request beruntun ke /api, kemudian catat status respons yang dihasilkan ketika batas terlampaui.
20. Sebelum Curtain di Shibuya resmi dibuka, Kusakabe memimpin audit untuk menguji kapasitas layanan. Dari terminal kusakabe, jalankan benchmark menggunakan Apache Benchmark dengan parameter -n 600 -c 30 menuju http://jujutsu.<xxxx>.com/. Catat Requests per Second (RPS), latensi, dan jumlah request yang gagal. Lakukan pengujian tambahan pada endpoint /api untuk mengamati efek rate limiting. Bandingkan hasil pengujian baseline dengan hasil ketika rate limiting aktif, serta gunakan access log gojo untuk membedakan kegagalan aplikasi, koneksi, dan request yang ditolak oleh kebijakan rate limit.
