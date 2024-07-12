#!/bin/bash
set -e

# Move to the parent directory containing sera-db-cloning.sh
cd "$(dirname "$0")/.."

# Run the MongoDB cloning script
echo "Running MongoDB cloning..."
echo "$PWD"
sed -i 's/\r$//' ./sera-mongodb/entrypoint.sh
./sera-mongodb/entrypoint.sh

# Replace variables in Nginx configuration and start Nginx
echo "Configuring Nginx..."
envsubst < ./sera-nginx/nginx.conf > /etc/nginx/nginx.conf
./sera-nginx/entrypoint.sh

export COREDNS_IP=$(hostname -I | awk '{print $1}')

echo "Starting etcd and CoreDNS Services"
nohup etcd --config-file=./sera-artifacts/sera-coredns/etcd.conf.yml &
coredns -conf ./sera-artifacts/sera-coredns/Corefile
