#!/bin/bash
echo "=== BENCHMARK APACHE BENCHMARK (SOAL 20) ==="

# Instal apache2-utils jika belum ada
apk update
apk add apache2-utils

echo -e "\n[1. Benchmark Frontend jujutsu.k29.com (-n 600 -c 30)]"
ab -n 600 -c 30 http://jujutsu.k29.com/

echo -e "\n[2. Benchmark API jujutsu.k29.com/api (-n 600 -c 30)]"
ab -n 600 -c 30 http://jujutsu.k29.com/api
