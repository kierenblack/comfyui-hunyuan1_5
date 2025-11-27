# Deployment Guide - Updated Handler

## Changes Made

### 1. Fixed Dockerfile
- ❌ Removed invalid `--rp_serve_api` flag
- ✅ Updated CMD to: `./builder.sh && python handler.py`

### 2. Enhanced Handler Logging
- ✅ Added initialization debug logging
- ✅ Added request-level debug logging
- ✅ Added error handling with traceback

### 3. Created Test Scripts
- ✅ `test_runpod_local.py` - Test locally with proper endpoints
- ✅ `test_handler_directly.py` - Test handler function directly
- ✅ `TROUBLESHOOTING.md` - Comprehensive debug guide

## How to Deploy Updated Code

### Step 1: Build New Docker Image

```bash
cd /workspaces/comfyui-hunyuan1_5

# Build with a new tag
docker build -t your-dockerhub-username/comfyui-hunyuan:latest .

# Or with version tag
docker build -t your-dockerhub-username/comfyui-hunyuan:v1.1 .
```

### Step 2: Push to Docker Hub

```bash
# Login to Docker Hub
docker login

# Push the image
docker push your-dockerhub-username/comfyui-hunyuan:latest

# Or versioned
docker push your-dockerhub-username/comfyui-hunyuan:v1.1
```

### Step 3: Update RunPod Endpoint

**Option A: Via RunPod Console**
1. Go to your endpoint settings
2. Update the Docker image tag
3. Save and redeploy

**Option B: Create New Endpoint**
1. Create new serverless endpoint
2. Use your updated Docker image
3. Configure same settings (GPU, disk, network volume)
4. Test with new endpoint

### Step 4: Verify Deployment

Check the logs for these new messages:

```
==========================================
INITIALIZING RUNPOD SERVERLESS WORKER
==========================================
Starting ComfyUI server...
Handler function: <function handler at 0x...>
Handler callable: True
Starting RunPod serverless worker...
```

If you see these, the updated code is deployed.

### Step 5: Test the Endpoint

```python
import requests

endpoint_id = "your-endpoint-id"
api_key = "your-runpod-api-key"

# Test with small image
test_input = {
    "input": {
        "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
        "prompt": "smooth motion",
        "num_frames": 16,
        "fps": 24,
        "steps": 15
    }
}

# Use runsync for immediate results (good for testing)
response = requests.post(
    f"https://api.runpod.ai/v2/{endpoint_id}/runsync",
    headers={"Authorization": f"Bearer {api_key}"},
    json=test_input,
    timeout=300
)

print("Status:", response.status_code)
print("Response:", response.json())
```

You should now see in the logs:

```
============================================================
HANDLER CALLED - NEW REQUEST RECEIVED
Job ID: xyz-123
============================================================
Processing job: xyz-123
Uploaded image: input_image.png
Queueing workflow in ComfyUI...
```

## Testing Locally Before Deploying

To save time, test locally first:

```bash
# Start handler locally
python handler.py

# In another terminal
python test_runpod_local.py sync
```

This will quickly verify the handler works before pushing to Docker Hub.

## Quick Local Test with Docker

Test the updated image locally before pushing:

```bash
# Build
docker build -t comfyui-hunyuan-test .

# Run
docker run --rm -it \
  --gpus all \
  -p 8188:8188 \
  -p 8000:8000 \
  comfyui-hunyuan-test

# In another terminal, test
python test_runpod_local.py sync
```

## Troubleshooting After Deployment

### Handler Still Not Called?

1. **Check logs for initialization messages**
   - Look for "INITIALIZING RUNPOD SERVERLESS WORKER"
   - If not present, old image is still running

2. **Verify image was updated**
   ```bash
   # Check what's running
   docker ps
   
   # Check image tag
   docker images | grep comfyui-hunyuan
   ```

3. **Force pull new image**
   On RunPod, sometimes you need to delete and recreate the endpoint to force a fresh pull

4. **Check RunPod dashboard**
   - View endpoint logs in real-time
   - Check for any errors during startup

### Logs Show Initialization But Handler Not Called?

This means the updated code is running, but requests aren't reaching the handler.

**Possible causes:**

1. **Wrong endpoint URL** - Make sure using `/runsync` or `/run`
2. **Authentication** - Check API key is valid
3. **Request format** - Must have `{"input": {...}}` structure
4. **Timeout** - Endpoint might be cold starting (takes 30-60 seconds)

**Debug steps:**

```python
# Test with verbose output
import requests

response = requests.post(
    f"https://api.runpod.ai/v2/{endpoint_id}/runsync",
    headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    },
    json={"input": {"image": "...", "prompt": "test"}},
    timeout=300
)

print(f"Status Code: {response.status_code}")
print(f"Headers: {response.headers}")
print(f"Body: {response.text}")
```

## Docker Hub Setup

If you haven't set up Docker Hub yet:

```bash
# Create account at hub.docker.com

# Login
docker login

# Tag your image (replace with your username)
docker tag comfyui-hunyuan-test YOUR_USERNAME/comfyui-hunyuan:latest

# Push
docker push YOUR_USERNAME/comfyui-hunyuan:latest
```

Then use `YOUR_USERNAME/comfyui-hunyuan:latest` as the image in RunPod.

## Summary Checklist

- [ ] Code changes made (Dockerfile, handler.py)
- [ ] Tested locally with `python handler.py` + `test_runpod_local.py`
- [ ] Docker image built
- [ ] Image pushed to Docker Hub
- [ ] RunPod endpoint updated with new image
- [ ] Endpoint restarted/redeployed
- [ ] Logs checked for "INITIALIZING RUNPOD SERVERLESS WORKER"
- [ ] Test request sent to `/runsync`
- [ ] Logs checked for "HANDLER CALLED - NEW REQUEST RECEIVED"

## Expected Timeline

- Local test: 5-10 minutes (first ComfyUI start)
- Docker build: 10-15 minutes
- Docker push: 5-10 minutes (depends on internet)
- RunPod cold start: 30-60 seconds (with network volume)
- First request: 2-5 minutes (model loading + generation)

## Need Help?

If handler still not being called after all this:

1. Share the FULL logs from a fresh endpoint start
2. Share the exact curl/Python command you're using to test
3. Confirm you see the new debug messages in logs
4. Check RunPod dashboard for any error messages
