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
