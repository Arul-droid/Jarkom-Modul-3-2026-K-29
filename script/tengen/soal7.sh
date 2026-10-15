#!/bin/bash
echo "=== VALIDASI DATABASE LEASE DHCP SERVER (SOAL 7) ==="

echo -e "\nMenampilkan daftar IP dinamis yang telah disewakan:"
cat /var/lib/dhcp/dhcpd.leases | grep -E "lease|binding state|hardware ethernet"

echo -e "\n=== VALIDASI SELESAI ==="
echo "Catatan: IP 10.78.3.99 milik Kugisaki tidak akan muncul di sini karena menggunakan static lease."
