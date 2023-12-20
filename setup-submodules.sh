#!/bin/sh
# Script to set up submodules

# List all your submodule directories
submodules=(
  "fe_Builder"
  "fe_Catalog"
  "be_Builder"
  "be_Socket"
  "be_Router"
  "be_Sequencer"
)

# Loop through each submodule and run npm install
for submodule in "${submodules[@]}"; do
  echo "Setting up $submodule..."
  cd "$submodule" && npm install && cd ..
done

echo "Submodule setup complete."
