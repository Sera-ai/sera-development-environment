# Array of service details
$services = @(
    @{ ImageName = "frontend_catalog"; ContextDir = "../fe_Catalog"; Dockerfile = "Dockerfile" }
    @{ ImageName = "backend_builder"; ContextDir = "../be_Builder"; Dockerfile = "Dockerfile" }
    @{ ImageName = "backend_socket"; ContextDir = "../be_Socket"; Dockerfile = "Dockerfile" }
    @{ ImageName = "backend_sequencer"; ContextDir = "../be_Sequencer"; Dockerfile = "Dockerfile" }
    @{ ImageName = "backend_processor"; ContextDir = "../be_Processor"; Dockerfile = "Dockerfile" }
)

# Function to build Docker images
function Build-DockerImage {
    param (
        [string]$ImageName,
        [string]$ContextDir,
        [string]$Dockerfile
    )

    cd "$ContextDir"
    Write-Host "Building Docker image $ImageName from context $ContextDir with Dockerfile $Dockerfile..."
    docker build -t $ImageName -f Dockerfile .

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error building Docker image $ImageName." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "Successfully built Docker image $ImageName." -ForegroundColor Green
    }
}

# Loop through services array and build each Docker image
foreach ($service in $services) {
    Build-DockerImage -ImageName $service.ImageName -ContextDir $service.ContextDir -Dockerfile $service.Dockerfile
}

Write-Host "All Docker images built successfully." -ForegroundColor Green
