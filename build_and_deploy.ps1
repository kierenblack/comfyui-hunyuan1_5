# PowerShell script for building and deploying ComfyUI Hunyuan 1.5 on Windows
# Run with: .\build_and_deploy.ps1

Write-Host "========================================" -ForegroundColor Green
Write-Host "ComfyUI Hunyuan 1.5 - Build & Deploy" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if Docker is installed
try {
    docker --version | Out-Null
    Write-Host "✓ Docker found" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker not found. Please install Docker Desktop for Windows" -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Get Docker Hub username
$dockerUser = Read-Host "Enter your Docker Hub username"

if ([string]::IsNullOrWhiteSpace($dockerUser)) {
    Write-Host "Error: Docker Hub username required" -ForegroundColor Red
    exit 1
}

# Get version tag
$version = Read-Host "Enter version tag (default: latest)"
if ([string]::IsNullOrWhiteSpace($version)) {
    $version = "latest"
}

$imageName = "$dockerUser/comfyui-hunyuan"
$fullTag = "${imageName}:${version}"

Write-Host ""
Write-Host "Building image: $fullTag" -ForegroundColor Yellow
Write-Host ""

# Build
docker build -t $fullTag .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✓ Build successful" -ForegroundColor Green
Write-Host ""

# Ask if want to push
$push = Read-Host "Push to Docker Hub? (y/n)"

if ($push -eq "y" -or $push -eq "Y") {
    Write-Host "Logging in to Docker Hub..." -ForegroundColor Yellow
    docker login
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Docker login failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Pushing $fullTag..." -ForegroundColor Yellow
    docker push $fullTag
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Push failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "✓ Push successful" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Deployment Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Docker image: $fullTag"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Go to RunPod console"
    Write-Host "2. Update your endpoint to use: $fullTag"
    Write-Host "3. Save and redeploy"
    Write-Host "4. Check logs for: 'INITIALIZING RUNPOD SERVERLESS WORKER'"
    Write-Host "5. Test with: python test_runpod_local.py"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Image built but not pushed" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To push later:"
    Write-Host "  docker push $fullTag"
    Write-Host ""
    Write-Host "To test locally (requires WSL2 with GPU support):"
    Write-Host "  docker run --rm -it --gpus all -p 8188:8188 -p 8000:8000 $fullTag"
    Write-Host ""
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
