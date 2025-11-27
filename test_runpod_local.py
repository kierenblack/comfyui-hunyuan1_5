#!/usr/bin/env python3
"""
Test RunPod handler locally by sending HTTP requests to the correct endpoint
"""

import requests
import json
import time

# RunPod serverless local endpoint
# When running locally, RunPod SDK creates these endpoints:
# POST /run - async execution
# POST /runsync - synchronous execution  
# POST /status/{job_id} - check status

BASE_URL = "http://localhost:8000"

def test_sync():
    """Test synchronous endpoint"""
    print("=" * 60)
    print("Testing /runsync endpoint")
    print("=" * 60)
    
    payload = {
        "input": {
            "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
            "prompt": "smooth cinematic motion, high quality",
            "num_frames": 16,
            "fps": 24,
            "steps": 15
        }
    }
    
    try:
        print(f"Sending request to {BASE_URL}/runsync")
        print("Payload:", json.dumps(payload, indent=2))
        
        response = requests.post(
            f"{BASE_URL}/runsync",
            json=payload,
            timeout=300
        )
        
        print(f"\nStatus Code: {response.status_code}")
        print("Response:")
        print(json.dumps(response.json(), indent=2))
        
        return response.json()
        
    except requests.exceptions.ConnectionError as e:
        print(f"Connection Error: {e}")
        print("Make sure handler.py is running with: python handler.py")
        return None
    except requests.exceptions.Timeout:
        print("Request timed out")
        return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def test_async():
    """Test async endpoint"""
    print("\n" + "=" * 60)
    print("Testing /run endpoint (async)")
    print("=" * 60)
    
    payload = {
        "input": {
            "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
            "prompt": "smooth cinematic motion, high quality",
            "num_frames": 16,
            "fps": 24,
            "steps": 15
        }
    }
    
    try:
        print(f"Sending request to {BASE_URL}/run")
        
        response = requests.post(
            f"{BASE_URL}/run",
            json=payload,
            timeout=10
        )
        
        print(f"\nStatus Code: {response.status_code}")
        result = response.json()
        print("Response:", json.dumps(result, indent=2))
        
        if "id" in result:
            job_id = result["id"]
            print(f"\nJob ID: {job_id}")
            print("Checking status...")
            
            # Poll status
            for i in range(60):
                time.sleep(2)
                status_response = requests.get(f"{BASE_URL}/status/{job_id}")
                status = status_response.json()
                
                print(f"Status: {status.get('status', 'unknown')}")
                
                if status.get("status") == "COMPLETED":
                    print("\nJob completed!")
                    print(json.dumps(status, indent=2))
                    break
                elif status.get("status") == "FAILED":
                    print("\nJob failed!")
                    print(json.dumps(status, indent=2))
                    break
        
        return result
        
    except Exception as e:
        print(f"Error: {e}")
        return None

def check_health():
    """Check if server is running"""
    print("=" * 60)
    print("Checking server health")
    print("=" * 60)
    
    try:
        # Try root endpoint
        response = requests.get(f"{BASE_URL}/", timeout=5)
        print(f"GET / - Status: {response.status_code}")
        print(f"Response: {response.text[:200]}")
    except Exception as e:
        print(f"GET / - Error: {e}")
    
    try:
        # Try health endpoint (common in RunPod)
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        print(f"GET /health - Status: {response.status_code}")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"GET /health - Error: {e}")

if __name__ == "__main__":
    import sys
    
    mode = sys.argv[1] if len(sys.argv) > 1 else "sync"
    
    print(f"Testing RunPod handler locally (mode: {mode})")
    print()
    
    check_health()
    print()
    
    if mode == "sync":
        test_sync()
    elif mode == "async":
        test_async()
    elif mode == "both":
        test_sync()
        test_async()
    else:
        print(f"Unknown mode: {mode}")
        print("Usage: python test_runpod_local.py [sync|async|both]")
