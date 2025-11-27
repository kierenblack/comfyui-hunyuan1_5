# Troubleshooting Handler Not Being Called

## Problem
Handler function never receives requests - the "HANDLER CALLED" debug message never appears in logs, even though:
- ✅ ComfyUI starts successfully  
- ✅ RunPod worker starts successfully
- ✅ Uvicorn running on localhost:8000

## Root Cause Analysis

### Issue #1: Testing Method
**Are you testing the endpoint correctly?**

RunPod serverless exposes these endpoints:
- `POST /run` - Async execution (returns job ID immediately)
- `POST /runsync` - Synchronous execution (waits for completion)
- `GET /status/{job_id}` - Check async job status

**Common mistake:** Sending request to `http://localhost:8000` without the `/runsync` or `/run` path.

### Issue #2: Local vs Deployed Testing
- **Local testing:** Must start handler with `python handler.py` and hit `http://localhost:8000/runsync`
- **RunPod deployed:** Must use full RunPod API URL with auth: `https://api.runpod.ai/v2/{endpoint_id}/runsync`

### Issue #3: Request Format
RunPod expects this format:
```json
{
  "input": {
    "your": "parameters"
  }
}
```

NOT:
```json
{
  "your": "parameters"
}
```

## Testing Steps

### Step 1: Test Locally

1. Start the handler:
```bash
cd /workspaces/comfyui-hunyuan1_5
python handler.py
```

2. Wait for these messages:
```
ComfyUI server is ready!
Starting RunPod serverless worker...
INFO:     Uvicorn running on http://localhost:8000
```

3. In another terminal, run the test:
```bash
python test_runpod_local.py sync
```

This will send a request to `http://localhost:8000/runsync` with proper format.

### Step 2: Check What's Actually Listening

```bash
# Check if port 8000 is listening
sudo netstat -tlnp | grep 8000

# Or use lsof
sudo lsof -i :8000
```

### Step 3: Test with curl

```bash
curl -X POST http://localhost:8000/runsync \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
      "prompt": "test",
      "num_frames": 16,
      "fps": 24,
      "steps": 15
    }
  }'
```

## Possible Fixes

### Fix #1: Ensure Handler is Properly Registered

The handler.py has been updated to include debug logging:

```python
if __name__ == "__main__":
    print("=" * 60)
    print("INITIALIZING RUNPOD SERVERLESS WORKER")
    print("=" * 60)
    
    if not start_comfyui():
        print("Failed to start ComfyUI. Exiting.")
        sys.exit(1)
    
    try:
        print("Starting RunPod serverless worker...")
        print(f"Handler function: {handler}")
        print(f"Handler callable: {callable(handler)}")
        runpod.serverless.start({"handler": handler})
    except Exception as e:
        print(f"Error starting serverless worker: {e}")
        traceback.print_exc()
```

This will help identify if the handler is properly set up.

### Fix #2: Check Dockerfile CMD

Updated Dockerfile to remove invalid `--rp_serve_api` flag:

```dockerfile
CMD ["/bin/bash", "-c", "./builder.sh && python handler.py"]
```

### Fix #3: Add Request Logging

The handler now logs every request at the very start:

```python
def handler(job):
    print("=" * 60)
    print("HANDLER CALLED - NEW REQUEST RECEIVED")
    print(f"Job ID: {job.get('id', 'unknown')}")
    print("=" * 60)
    # ... rest of handler
```

## Deployment Testing on RunPod

When deployed to RunPod, test with:

```python
import requests

endpoint_id = "your-endpoint-id"
api_key = "your-runpod-api-key"

response = requests.post(
    f"https://api.runpod.ai/v2/{endpoint_id}/runsync",
    headers={"Authorization": f"Bearer {api_key}"},
    json={
        "input": {
            "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
            "prompt": "test",
            "num_frames": 16
        }
    },
    timeout=300
)

print(response.json())
```

## What to Check in Logs

When you start the handler, you should see:

```
==========================================
INITIALIZING RUNPOD SERVERLESS WORKER
==========================================
Starting ComfyUI server...
ComfyUI server is ready!
Starting RunPod serverless worker...
Handler function: <function handler at 0x...>
Handler callable: True
--- Starting Serverless Worker | Version 1.8.1 ---
INFO:     Started server process [18]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://localhost:8000 (Press CTRL+C to quit)
```

When you send a request (to `/runsync` or `/run`), you should see:

```
============================================================
HANDLER CALLED - NEW REQUEST RECEIVED
Job ID: some-job-id
============================================================
Processing job: some-job-id
```

## If Handler Still Not Called

1. **Check RunPod SDK version:**
   ```bash
   pip show runpod
   ```
   Should be >= 1.5.0

2. **Check for errors in RunPod startup:**
   Look for any errors or warnings when `runpod.serverless.start()` is called

3. **Verify network connectivity:**
   Make sure port 8000 is accessible

4. **Check RunPod infrastructure:**
   On RunPod platform, check the endpoint logs for any routing errors

5. **Try minimal handler:**
   Create a simple test to isolate the issue:
   
   ```python
   def test_handler(job):
       print("TEST HANDLER CALLED!")
       return {"status": "success", "message": "test"}
   
   runpod.serverless.start({"handler": test_handler})
   ```

## Next Steps

1. Run `python test_runpod_local.py sync` to test locally
2. Check logs for "HANDLER CALLED" message
3. If still no message, try the minimal handler test
4. Report back with exact error messages or behaviors
