#!/bin/bash
set -e

# Start MongoDB in the background
mongod --fork --logpath /var/log/mongod.log --bind_ip_all

# Restore from dump
mongorestore --db Sera ./sera-db-mongo/Sera

# Stop the background MongoDB
mongod --shutdown

# Start MongoDB in the foreground
mongod --fork --logpath /var/log/mongod.log --bind_ip_all
echo "Setting up fe_Builder..."
npm install --prefix ./fe_Builder && npm --prefix ./fe_Builder run dev &

echo "Setting up fe_Catalog..."
npm install --prefix ./fe_Catalog && npm --prefix ./fe_Catalog run dev &

echo "Setting up be_Builder..."
npm install --prefix ./be_Builder && npm --prefix ./be_Builder run dev &

echo "Setting up be_Socket..."
npm install --prefix ./be_Socket && npm --prefix ./be_Socket run dev &

echo "Setting up be_Router..."
npm install --prefix ./be_Router && npm --prefix ./be_Router run dev &

echo "Setting up be_Sequencer..."
npm install --prefix ./be_Sequencer && npm --prefix ./be_Sequencer run dev &

echo "All submodules are set up and running in the background."
