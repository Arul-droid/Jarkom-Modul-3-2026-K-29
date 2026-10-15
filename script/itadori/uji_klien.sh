#!/bin/bash
echo "=== PENGUJIAN LENGKAP KLIEN ITADORI ==="

# 1. Pastikan tools terpasang (Alpine)
apk update
apk add bind-tools curl

# 2. Uji DNS Master & Slave (Soal 11)
echo -e "\n[1. Uji DNS Master Utahime (10.78.1.2)]"
dig @10.78.1.2 NS jujutsu.k29.com

echo -e "\n[2. Uji DNS Slave Shoko (10.78.1.3)]"
dig @10.78.1.3 NS jujutsu.k29.com

# 3. Uji CNAME, Reverse DNS (PTR), & Forwarder (Soal 12)
echo -e "\n[3. Uji CNAME www.jujutsu.k29.com]"
dig @10.78.1.2 www.jujutsu.k29.com

echo -e "\n[4. Uji Reverse DNS (PTR) 10.78.1.4]"
dig @10.78.1.2 -x 10.78.1.4

echo -e "\n[5. Uji DNS Forwarder google.com]"
dig @10.78.1.2 google.com

echo -e "\n[6. Uji Ping google.com]"
ping -c 3 google.com

# 4. Uji Akses Langsung ke Worker (Harus Ditolak/403) (Soal 14)
echo -e "\n[7. Uji Akses Langsung ke Frontend Maki (Harus Ditolak 403)]"
curl -i -H "Host: jujutsu.k29.com" http://10.78.4.12/

echo -e "\n[8. Uji Akses Langsung ke API Worker Nanami (Harus Ditolak 403)]"
curl -i -H "Host: jujutsu.k29.com" http://10.78.4.14/api

# 5. Uji Akses Melalui Domain jujutsu.k29.com /api (Soal 17)
echo -e "\n[9. Uji Akses API via Proxy Gojo -> Geto]"
curl -i http://jujutsu.k29.com/api
