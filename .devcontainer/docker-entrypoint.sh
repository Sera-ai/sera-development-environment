#!/bin/bash

# Function to start a Node.js app
start_app() {
  local label=$1
  local command=$2
  local cwd=$3

  echo "Starting $label..."
  (cd "$cwd" && $command) &
}

# Start the applications
start_app "fe_Catalog" "npm run dev" "./sera-frontend"
start_app "be_Builder" "nodemon" "./sera-backend-core"
start_app "be_Socket" "nodemon" "./sera-backend-socket"
start_app "be_Sequencer" "nodemon" "./sera-backend-sequencer"
start_app "be_Processor" "nodemon" "./sera-backend-processor"

# Wait for all background jobs to finish
wait

echo "All applications started."
