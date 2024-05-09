#!/bin/bash
set -e

# Move to the parent directory containing sera-db-cloning.sh
cd "$(dirname "$0")/.."

# Run the MongoDB cloning script
echo "Running MongoDB cloning..."
echo "$PWD"
sed -i 's/\r$//' ./sera-db-mongo/entrypoint.sh
./sera-db-mongo/entrypoint.sh

# Replace variables in Nginx configuration and start Nginx
echo "Configuring Nginx..."
envsubst < ./.devcontainer/nginx.conf > /etc/nginx/nginx.conf
sed -i 's/___/\$/g' /etc/nginx/nginx.conf

# Start Nginx in foreground
echo "Starting Nginx..."
exec nginx -g 'daemon off;'
