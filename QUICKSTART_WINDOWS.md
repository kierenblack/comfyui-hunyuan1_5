# Quick Start for Windows Users

## TL;DR

**On Windows PowerShell:**
```powershell
.\build_and_deploy.ps1
```

**That's it!** Follow the prompts, then update your RunPod endpoint.

---

## Prerequisites (5 minutes)

1. **Install Docker Desktop for Windows**
   - Download: https://www.docker.com/products/docker-desktop
   - Install and restart
   - Make sure the Docker whale icon appears in system tray

2. **Create Docker Hub account** (if you don't have one)
   - Sign up: https://hub.docker.com

---

## Deployment Steps (30 minutes)

### 1. Open PowerShell

- Press `Win + X`
- Select "Windows PowerShell" or "Terminal"
- Navigate to your project:
  ```powershell
  cd C:\path\to\comfyui-hunyuan1_5
  ```

### 2. Run the deployment script

```powershell
.\build_and_deploy.ps1
```

**If you get an error about execution policy:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\build_and_deploy.ps1
```

### 3. Follow the prompts

1. **Enter Docker Hub username:** `your-username`
2. **Enter version tag:** Just press Enter for "latest"
3. **Wait for build:** 10-15 minutes ☕
4. **Push to Docker Hub?** Type `y` and press Enter
5. **Docker login:** Enter your Docker Hub password when prompted

### 4. Update RunPod endpoint

1. Go to https://www.runpod.io/console/serverless
2. Click your endpoint
3. Click "Edit"
4. Update **Container Image** to: `your-username/comfyui-hunyuan:latest`
5. Click "Save"
6. Wait for deployment (~1 minute)

### 5. Test it!

**Check the logs:**
- Look for: `INITIALIZING RUNPOD SERVERLESS WORKER`
- Look for: `Handler callable: True`

**Send a test request:**
```python
import requests

endpoint_id = "your-endpoint-id"
api_key = "your-api-key"

response = requests.post(
    f"https://api.runpod.ai/v2/{endpoint_id}/runsync",
    headers={"Authorization": f"Bearer {api_key}"},
    json={
        "input": {
            "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
            "prompt": "smooth motion test",
            "num_frames": 16
        }
    }
)

print(response.json())
```

**In the logs you should see:**
```
HANDLER CALLED - NEW REQUEST RECEIVED
Job ID: abc-123
Processing job...
```

✅ **Success!** Your handler is now working.

---

## Alternative Methods

### Don't want to use PowerShell?

**Option 1: Use Git Bash** (if you have Git for Windows)
```bash
./build_and_deploy.sh
```

**Option 2: Use WSL** (if you have Windows Subsystem for Linux)
```bash
cd /mnt/c/path/to/project
./build_and_deploy.sh
```

**Option 3: Use GitHub Actions** (no local build needed)
- Push code to GitHub
- Set up GitHub Actions (see WINDOWS.md)
- GitHub builds and pushes automatically

**Option 4: Manual commands**
```powershell
docker build -t your-username/comfyui-hunyuan:latest .
docker login
docker push your-username/comfyui-hunyuan:latest
```

---

## Troubleshooting

### Docker Desktop not running?

**Error:** `error during connect... Is the docker daemon running?`

**Fix:** 
1. Open Docker Desktop from Start Menu
2. Wait for whale icon in system tray
3. Try again

### Script won't run?

**Error:** `running scripts is disabled`

**Fix:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Build fails?

**Error:** `no space left`

**Fix:**
1. Open Docker Desktop → Settings
2. Resources → Disk image size
3. Increase to 60+ GB
4. Apply & Restart

---

## Full Documentation

- **[WINDOWS.md](WINDOWS.md)** - Complete Windows guide with all methods
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - General deployment guide
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Debug procedures
- **[INDEX.md](INDEX.md)** - All documentation

---

## What This Fixes

Your handler wasn't being called due to a bug in the Dockerfile. The fix:
- ✅ Removed invalid `--rp_serve_api` argument
- ✅ Added debug logging
- ✅ Better error handling

**But you need to rebuild and redeploy for the fix to work!**

---

## Expected Results

**Build time:** 10-15 minutes  
**Push time:** 5-10 minutes  
**Deploy time:** 2 minutes  
**Cold start:** ~40 seconds (with network volume)  
**First request:** 2-5 minutes  

**Total:** ~30 minutes from start to working endpoint

---

## Questions?

- See [WINDOWS.md](WINDOWS.md) for detailed Windows instructions
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if issues persist
- Check logs for the debug messages mentioned above

**The fix is ready - just deploy it and you're good to go!** 🚀
