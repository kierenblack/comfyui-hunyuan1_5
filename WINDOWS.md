# Windows Deployment Guide

## Prerequisites

1. **Docker Desktop for Windows**
   - Download: https://www.docker.com/products/docker-desktop
   - Install and enable WSL 2 backend
   - Make sure it's running before building

2. **Git for Windows** (optional, for cloning repo)
   - Download: https://git-scm.com/download/win

3. **PowerShell** (included with Windows)

4. **Docker Hub Account**
   - Sign up at: https://hub.docker.com

## Method 1: PowerShell Script (Recommended)

### Step 1: Open PowerShell

1. Press `Win + X`
2. Select "Windows PowerShell" or "Terminal"
3. Navigate to your project folder:
   ```powershell
   cd C:\path\to\comfyui-hunyuan1_5
   ```

### Step 2: Run the Script

```powershell
.\build_and_deploy.ps1
```

**If you get an execution policy error:**

```powershell
# Option 1: Allow the script for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Then run the script
.\build_and_deploy.ps1

# Option 2: Unblock the script file
Unblock-File .\build_and_deploy.ps1
.\build_and_deploy.ps1
```

### Step 3: Follow Prompts

1. Enter your Docker Hub username
2. Enter version tag (or press Enter for "latest")
3. Wait for build (10-15 minutes)
4. Choose whether to push to Docker Hub
5. If yes, Docker will prompt for login

### Step 4: Update RunPod

1. Go to RunPod console
2. Update your endpoint image to: `your-username/comfyui-hunyuan:latest`
3. Save and redeploy

## Method 2: Manual Commands (Windows)

### Using PowerShell

```powershell
# Set your Docker Hub username
$env:DOCKER_USER = "your-username"

# Build the image
docker build -t ${env:DOCKER_USER}/comfyui-hunyuan:latest .

# Login to Docker Hub
docker login

# Push the image
docker push ${env:DOCKER_USER}/comfyui-hunyuan:latest
```

### Using Command Prompt (CMD)

```cmd
# Set your Docker Hub username
set DOCKER_USER=your-username

# Build the image
docker build -t %DOCKER_USER%/comfyui-hunyuan:latest .

# Login to Docker Hub
docker login

# Push the image
docker push %DOCKER_USER%/comfyui-hunyuan:latest
```

## Method 3: Using Git Bash (if installed)

If you have Git for Windows installed, you can use the bash script:

```bash
# Open Git Bash
# Navigate to project
cd /c/path/to/comfyui-hunyuan1_5

# Run the bash script
./build_and_deploy.sh
```

## Method 4: Using WSL (Windows Subsystem for Linux)

If you have WSL installed:

```bash
# Open WSL terminal (Ubuntu, etc.)
# Navigate to project (Windows paths are under /mnt/)
cd /mnt/c/path/to/comfyui-hunyuan1_5

# Run the bash script
./build_and_deploy.sh
```

## Troubleshooting Windows Issues

### Issue: Docker Desktop not running

**Error:** `error during connect: ... Is the docker daemon running?`

**Solution:**
1. Open Docker Desktop from Start Menu
2. Wait for it to fully start (whale icon in system tray)
3. Try the build command again

### Issue: PowerShell script won't run

**Error:** `cannot be loaded because running scripts is disabled`

**Solution:**
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or for just this session
Set-ExecutionPolicy Bypass -Scope Process
```

### Issue: Path not found

**Solution:**
```powershell
# Use absolute path
cd "C:\Users\YourName\Projects\comfyui-hunyuan1_5"

# Check you're in the right place
dir
# Should see Dockerfile, handler.py, etc.
```

### Issue: Docker build fails with "no space left"

**Solution:**
1. Open Docker Desktop
2. Go to Settings → Resources → Disk image size
3. Increase to at least 60 GB
4. Apply & Restart

### Issue: WSL 2 not enabled

**Error:** `WSL 2 installation is incomplete`

**Solution:**
1. Open PowerShell as Administrator
2. Run: `wsl --install`
3. Restart computer
4. Open Docker Desktop and enable WSL 2 backend in settings

## Testing Locally on Windows

### With Docker Desktop

```powershell
# Build the image
docker build -t comfyui-hunyuan-test .

# Run (requires WSL 2 with GPU support)
docker run --rm -it `
  --gpus all `
  -p 8188:8188 `
  -p 8000:8000 `
  comfyui-hunyuan-test
```

**Note:** GPU passthrough on Windows requires:
- Docker Desktop with WSL 2 backend
- WSL 2 with GPU drivers
- NVIDIA GPU with recent drivers

### Testing Handler Script

```powershell
# Install Python 3.11+ from python.org

# Install requirements
pip install runpod requests Pillow

# Run verification
python verify_setup.py

# Test handler locally (if you have GPU and models)
python handler.py
```

## Docker Desktop Settings for Windows

### Recommended Settings

1. **General:**
   - ✅ Use WSL 2 based engine
   - ✅ Start Docker Desktop when you log in (optional)

2. **Resources:**
   - **Memory:** 8 GB minimum (for local testing)
   - **CPUs:** 4+ cores
   - **Disk image size:** 60 GB minimum

3. **WSL Integration:**
   - ✅ Enable integration with default WSL distro
   - ✅ Enable integration with additional distros (if any)

## Quick Reference Card

### PowerShell Commands

```powershell
# Navigate to project
cd C:\path\to\comfyui-hunyuan1_5

# Run deployment script
.\build_and_deploy.ps1

# Or manual build
docker build -t username/comfyui-hunyuan:latest .
docker login
docker push username/comfyui-hunyuan:latest
```

### Testing Commands

```powershell
# Verify setup
python verify_setup.py

# Test handler (requires running handler)
python test_runpod_local.py sync
```

## File Paths on Windows

Windows uses backslashes (`\`) for paths, but in PowerShell you can use forward slashes (`/`) too:

```powershell
# Both work in PowerShell
cd C:\Users\YourName\Projects\comfyui-hunyuan1_5
cd C:/Users/YourName/Projects/comfyui-hunyuan1_5

# In Docker commands, use forward slashes
docker run -v C:/path/to/models:/app/models ...
```

## Alternative: Use RunPod's Build Feature

If Docker on Windows is problematic, you can:

1. **Push code to GitHub**
   ```powershell
   git add .
   git commit -m "Fixed handler"
   git push origin main
   ```

2. **Use RunPod's Docker build**
   - Create a new template in RunPod
   - Point to your GitHub repo
   - RunPod will build the image for you
   - No local Docker required!

3. **Or use GitHub Actions** (see below)

## GitHub Actions (No Local Build Needed)

Create `.github/workflows/docker-build.yml`:

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/comfyui-hunyuan:latest
```

Then:
1. Add secrets to GitHub (Settings → Secrets → Actions)
2. Push to GitHub
3. GitHub builds and pushes automatically
4. No local Docker needed!

## Summary

**Easiest methods on Windows:**

1. **PowerShell script** - `.\build_and_deploy.ps1` (requires Docker Desktop)
2. **Git Bash** - `./build_and_deploy.sh` (if Git for Windows installed)
3. **GitHub Actions** - No local build, GitHub does it for you
4. **RunPod Build** - Let RunPod build from your GitHub repo

**Choose based on your setup:**
- Have Docker Desktop? → Use PowerShell script
- Have Git Bash? → Use bash script
- Don't want local Docker? → Use GitHub Actions or RunPod Build

## Need Help?

**Docker Desktop issues:**
- https://docs.docker.com/desktop/troubleshoot/overview/

**WSL 2 issues:**
- https://docs.microsoft.com/en-us/windows/wsl/troubleshooting

**PowerShell execution policy:**
- Run PowerShell as Administrator
- `Set-ExecutionPolicy RemoteSigned`
