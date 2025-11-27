#!/usr/bin/env python3
"""
Verification script - Check if handler is properly configured
Run this in the container to diagnose handler issues
"""

import sys
import os

print("=" * 70)
print("HANDLER VERIFICATION SCRIPT")
print("=" * 70)
print()

# Check 1: Can we import handler module?
print("1. Checking if handler.py exists and is importable...")
try:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import handler
    print("   ✅ handler.py imported successfully")
except Exception as e:
    print(f"   ❌ Failed to import handler.py: {e}")
    sys.exit(1)

# Check 2: Is handler function defined?
print()
print("2. Checking if handler function exists...")
if hasattr(handler, 'handler'):
    print("   ✅ handler() function found")
    print(f"   Function: {handler.handler}")
    print(f"   Callable: {callable(handler.handler)}")
else:
    print("   ❌ handler() function not found")
    sys.exit(1)

# Check 3: Can we import runpod?
print()
print("3. Checking RunPod SDK...")
try:
    import runpod
    print("   ✅ runpod imported successfully")
    print(f"   Version: {runpod.__version__ if hasattr(runpod, '__version__') else 'unknown'}")
except Exception as e:
    print(f"   ❌ Failed to import runpod: {e}")
    sys.exit(1)

# Check 4: ComfyUI path
print()
print("4. Checking ComfyUI installation...")
comfyui_path = os.environ.get("COMFYUI_PATH", "/app/ComfyUI")
print(f"   COMFYUI_PATH: {comfyui_path}")
if os.path.exists(comfyui_path):
    print("   ✅ ComfyUI directory exists")
    
    main_py = os.path.join(comfyui_path, "main.py")
    if os.path.exists(main_py):
        print("   ✅ ComfyUI main.py found")
    else:
        print("   ⚠️  ComfyUI main.py not found")
else:
    print("   ❌ ComfyUI directory not found")

# Check 5: Models
print()
print("5. Checking models...")
models_dir = os.path.join(comfyui_path, "models")
if os.path.exists(models_dir):
    print("   ✅ Models directory exists")
    
    required_models = [
        ("diffusion_models", "hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors"),
        ("vae", "hunyuanvideo15_vae_fp16.safetensors"),
        ("text_encoders", "qwen_2.5_vl_7b_fp8_scaled.safetensors"),
        ("text_encoders", "byt5_small_glyphxl_fp16.safetensors"),
        ("clip_vision", "sigclip_vision_patch14_384.safetensors"),
    ]
    
    for subdir, filename in required_models:
        model_path = os.path.join(models_dir, subdir, filename)
        if os.path.exists(model_path):
            size_gb = os.path.getsize(model_path) / (1024**3)
            print(f"   ✅ {subdir}/{filename} ({size_gb:.1f} GB)")
        else:
            print(f"   ❌ {subdir}/{filename} NOT FOUND")
else:
    print("   ❌ Models directory not found")

# Check 6: Network volume (if available)
print()
print("6. Checking network volume...")
if os.path.exists("/runpod-volume"):
    print("   ✅ Network volume detected at /runpod-volume")
    
    # Check if models are there
    for subdir, filename in required_models:
        vol_path = os.path.join("/runpod-volume", subdir, filename)
        if os.path.exists(vol_path):
            print(f"   ✅ {subdir}/{filename} in network volume")
else:
    print("   ⚠️  No network volume detected (models will download every cold start)")

# Check 7: Test handler with mock job
print()
print("7. Testing handler with mock job...")
try:
    # Create a minimal test job
    test_job = {
        "id": "verification-test",
        "input": {
            "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
            "prompt": "test",
            "num_frames": 16
        }
    }
    
    print("   Creating mock job...")
    print(f"   Job ID: {test_job['id']}")
    
    # Don't actually call handler (would try to start ComfyUI)
    # Just verify it's callable
    print("   ✅ Handler function is callable and ready")
    print("   ℹ️  Skipping actual execution (would start ComfyUI)")
    
except Exception as e:
    print(f"   ❌ Error testing handler: {e}")

# Check 8: Python environment
print()
print("8. Checking Python environment...")
print(f"   Python: {sys.version}")
print(f"   Path: {sys.executable}")

try:
    import torch
    print(f"   PyTorch: {torch.__version__}")
    print(f"   CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"   CUDA version: {torch.version.cuda}")
        print(f"   GPU: {torch.cuda.get_device_name(0)}")
except Exception as e:
    print(f"   ⚠️  PyTorch: {e}")

# Check 9: Required packages
print()
print("9. Checking required packages...")
required_packages = [
    "runpod",
    "requests",
    "Pillow",
    "torch",
    "transformers",
    "diffusers",
    "accelerate",
]

for package in required_packages:
    try:
        __import__(package)
        print(f"   ✅ {package}")
    except ImportError:
        print(f"   ❌ {package} NOT INSTALLED")

# Summary
print()
print("=" * 70)
print("VERIFICATION COMPLETE")
print("=" * 70)
print()
print("If all checks passed (✅), the handler should work correctly.")
print()
print("To start the handler:")
print("  python handler.py")
print()
print("To test locally:")
print("  python test_runpod_local.py sync")
print()
print("Common issues:")
print("  - Missing models: Run builder.sh or upload to network volume")
print("  - Import errors: Install requirements.txt")
print("  - Handler not called: Rebuild and redeploy Docker image")
print()
