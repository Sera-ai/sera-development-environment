#!/bin/bash

# Array of service details
services=(
  "frontend_catalog:../fe_Catalog:Dockerfile"
  "backend_builder:../be_Builder:Dockerfile"
  "backend_socket:../be_Socket:Dockerfile"
  "backend_sequencer:../be_Sequencer:Dockerfile"
  "backend_processor:../be_Processor:Dockerfile"
)

# Function to build Docker images
build_docker_image() {
  local image_name=$1
  local context_dir=$2
  local dockerfile=$3

  echo "Building Docker image ${image_name} from context ${context_dir} with Dockerfile ${dockerfile}..."
  docker build -t "${image_name}" -f "${context_dir}/${dockerfile}" "${context_dir}"

  if [ $? -ne 0 ]; then
    echo "Error building Docker image ${image_name}."
    exit 1
  else
    echo "Successfully built Docker image ${image_name}."
  fi
}

# Loop through services array and build each Docker image
for service in "${services[@]}"; do
  IFS=":" read -r image_name context_dir dockerfile <<< "$service"
  build_docker_image "$image_name" "$context_dir" "$dockerfile"
done

echo "All Docker images built successfully."
