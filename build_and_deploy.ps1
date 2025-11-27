# PowerShell script for building and deploying ComfyUI Hunyuan 1.5 on Windows
# Run with: .\build_and_deploy.ps1

Write-Host "========================================" -ForegroundColor Green
Write-Host "ComfyUI Hunyuan 1.5 - Build & Deploy" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if Docker is installed
try {
    docker --version | Out-Null
    Write-Host "Docker found" -ForegroundColor Green
} catch {
    Write-Host "Docker not found. Please install Docker Desktop for Windows" -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

$imageName = "comfyui-hunyuan-test"

Write-Host ""
Write-Host "Building image for local testing: $imageName" -ForegroundColor Yellow
Write-Host ""

# Build
docker build -t $imageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build successful!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Local Test Image Built" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "To test locally (requires WSL2 with GPU support):"
Write-Host "  docker run --rm -it --gpus all -p 8188:8188 -p 8000:8000 $imageName"
Write-Host ""
Write-Host "For deployment:"
Write-Host "1. Push your code to GitHub"
Write-Host "2. In RunPod, create endpoint from GitHub repo"
Write-Host "3. RunPod will build the Docker image automatically"
Write-Host "4. Check logs for: INITIALIZING RUNPOD SERVERLESS WORKER"
Write-Host ""

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
