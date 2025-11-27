#!/usr/bin/env python3
"""
Direct handler test - bypasses RunPod infrastructure to test handler function directly
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Mock the handler function
from handler import handler

# Create a test job
test_job = {
    "id": "test-job-123",
    "input": {
        "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
        "prompt": "smooth cinematic motion, high quality",
        "num_frames": 16,
        "fps": 24,
        "steps": 15
    }
}

print("Testing handler function directly...")
print("=" * 60)

try:
    result = handler(test_job)
    print("\nHandler returned:")
    print(result)
except Exception as e:
    print(f"\nHandler raised exception: {e}")
    import traceback
    traceback.print_exc()
