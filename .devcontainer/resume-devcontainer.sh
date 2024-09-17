#!/bin/bash
set -e

FLAG_FILE="/var/tmp/flagfile"


if [ ! -f "$FLAG_FILE" ]; then
    # Initial startup actions
    echo "First time setup"
    # Create the flag file
    touch "$FLAG_FILE"
else

    # Configuration Variables
    MONGO_LOG_PATH="/var/log/mongod.log"
    MONGO_BIND_IP="0.0.0.0"
    REPLICA_SET_NAME="rs0"
    MONGO_PORT=27017

    # Function to wait for MongoDB to become available
    wait_for_mongo() {
        until mongosh --eval "print('MongoDB is up')" >/dev/null 2>&1; do
            echo "Waiting for MongoDB to start..."
            sleep 2
        done
    }

    echo "Starting MongoDB in the background..."
    mongod --fork --logpath "$MONGO_LOG_PATH" --bind_ip "$MONGO_BIND_IP" --replSet "$REPLICA_SET_NAME" --port $MONGO_PORT
    # Wait for MongoDB to be available
    wait_for_mongo

    # Wait for the replica set to be fully operational (skip re-initialization)
    until mongosh --eval "rs.status()" | grep -q "stateStr"; do
        echo "Waiting for replica set to become operational..."
        sleep 2
    done
    # Indicate that MongoDB is running
    echo "MongoDB instance resumed and is running."
    openresty -c /etc/nginx/nginx.conf 
    echo "Nginx instance resumed and is running."

fi