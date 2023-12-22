#!/bin/bash
set -e

# Start MongoDB in the background
mongod --fork --logpath /var/log/mongod.log --bind_ip_all

# Restore from dump
mongorestore ./sera-db-mongo/

# Stop the background MongoDB
mongod --shutdown

# Start MongoDB in the foreground
exec mongod --bind_ip_all
