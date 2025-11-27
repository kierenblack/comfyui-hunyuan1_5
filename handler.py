"""
RunPod Serverless Handler for ComfyUI with Hunyuan 1.5 Video
Handles img2vid generation requests via ComfyUI API
"""

import os
import json
import time
import base64
import requests
import runpod
from pathlib import Path
import subprocess
import signal
import sys

# Configuration
COMFYUI_PATH = os.environ.get("COMFYUI_PATH", "/app/ComfyUI")
COMFYUI_PORT = 8188
COMFYUI_URL = f"http://127.0.0.1:{COMFYUI_PORT}"

# Global process holder
comfyui_process = None


def start_comfyui():
    """Start ComfyUI server in background"""
    global comfyui_process
    
    print("Starting ComfyUI server...")
    comfyui_process = subprocess.Popen(
        ["python", "main.py", "--listen", "0.0.0.0", "--port", str(COMFYUI_PORT)],
        cwd=COMFYUI_PATH,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    # Wait for server to be ready
    max_retries = 60
    for i in range(max_retries):
        try:
            response = requests.get(f"{COMFYUI_URL}/system_stats", timeout=2)
            if response.status_code == 200:
                print("ComfyUI server is ready!")
                return True
        except requests.exceptions.RequestException:
            pass
        
        if i % 10 == 0:
            print(f"Waiting for ComfyUI server... ({i}/{max_retries})")
        time.sleep(1)
    
    print("Failed to start ComfyUI server")
    return False


def stop_comfyui():
    """Stop ComfyUI server"""
    global comfyui_process
    if comfyui_process:
        print("Stopping ComfyUI server...")
        comfyui_process.send_signal(signal.SIGTERM)
        comfyui_process.wait(timeout=10)


def upload_image(image_data, filename="input_image.png"):
    """Upload image to ComfyUI"""
    input_dir = os.path.join(COMFYUI_PATH, "input")
    os.makedirs(input_dir, exist_ok=True)
    
    # Handle base64 encoded images
    if isinstance(image_data, str):
        if image_data.startswith("data:image"):
            # Remove data:image/png;base64, prefix
            image_data = image_data.split(",", 1)[1]
        image_bytes = base64.b64decode(image_data)
    else:
        image_bytes = image_data
    
    # Save image
    image_path = os.path.join(input_dir, filename)
    with open(image_path, "wb") as f:
        f.write(image_bytes)
    
    return filename


def queue_prompt(workflow):
    """Queue a workflow in ComfyUI"""
    response = requests.post(f"{COMFYUI_URL}/prompt", json={"prompt": workflow})
    return response.json()


def get_history(prompt_id):
    """Get execution history for a prompt"""
    response = requests.get(f"{COMFYUI_URL}/history/{prompt_id}")
    return response.json()


def wait_for_completion(prompt_id, timeout=600):
    """Wait for workflow execution to complete"""
    start_time = time.time()
    
    while time.time() - start_time < timeout:
        history = get_history(prompt_id)
        
        if prompt_id in history:
            status = history[prompt_id].get("status", {})
            
            if status.get("completed", False):
                return history[prompt_id]
            
            if "error" in status:
                raise Exception(f"Workflow failed: {status['error']}")
        
        time.sleep(2)
    
    raise TimeoutError(f"Workflow execution timed out after {timeout}s")


def get_output_files(history_entry):
    """Extract output file information from history"""
    outputs = []
    
    if "outputs" not in history_entry:
        return outputs
    
    for node_id, node_output in history_entry["outputs"].items():
        if "videos" in node_output:
            for video in node_output["videos"]:
                outputs.append({
                    "type": "video",
                    "filename": video["filename"],
                    "subfolder": video.get("subfolder", ""),
                    "type_name": video.get("type", "output")
                })
        
        if "images" in node_output:
            for image in node_output["images"]:
                outputs.append({
                    "type": "image",
                    "filename": image["filename"],
                    "subfolder": image.get("subfolder", ""),
                    "type_name": image.get("type", "output")
                })
    
    return outputs


def get_file_as_base64(filename, subfolder="", file_type="output"):
    """Get file content as base64"""
    if subfolder:
        filepath = os.path.join(COMFYUI_PATH, file_type, subfolder, filename)
    else:
        filepath = os.path.join(COMFYUI_PATH, file_type, filename)
    
    if not os.path.exists(filepath):
        return None
    
    with open(filepath, "rb") as f:
        file_bytes = f.read()
        return base64.b64encode(file_bytes).decode("utf-8")


def create_default_workflow(input_image, prompt="", negative_prompt="", seed=None, num_frames=25, fps=24, steps=20, cfg=1, width=720, height=1280, shift=7):
    """Create a default Hunyuan 1.5 Video workflow based on actual workflow structure"""
    if seed is None:
        import random
        seed = random.randint(0, 2**32 - 1)
    
    # Actual Hunyuan 1.5 workflow structure from video_workflow.json
    workflow = {
        "8": {
            "inputs": {
                "samples": ["125", 0],
                "vae": ["10", 0]
            },
            "class_type": "VAEDecode",
            "_meta": {"title": "VAE Decode"}
        },
        "10": {
            "inputs": {
                "vae_name": "hunyuanvideo15_vae_fp16.safetensors"
            },
            "class_type": "VAELoader",
            "_meta": {"title": "Load VAE"}
        },
        "11": {
            "inputs": {
                "clip_name1": "qwen_2.5_vl_7b_fp8_scaled.safetensors",
                "clip_name2": "byt5_small_glyphxl_fp16.safetensors",
                "type": "hunyuan_video_15",
                "device": "default"
            },
            "class_type": "DualCLIPLoader",
            "_meta": {"title": "DualCLIPLoader"}
        },
        "12": {
            "inputs": {
                "unet_name": "hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors",
                "weight_dtype": "default"
            },
            "class_type": "UNETLoader",
            "_meta": {"title": "Load Diffusion Model"}
        },
        "44": {
            "inputs": {
                "text": prompt if prompt else "high quality, smooth motion, cinematic",
                "clip": ["11", 0]
            },
            "class_type": "CLIPTextEncode",
            "_meta": {"title": "CLIP Text Encode (Positive Prompt)"}
        },
        "78": {
            "inputs": {
                "width": width,
                "height": height,
                "length": num_frames,
                "batch_size": 1,
                "positive": ["44", 0],
                "negative": ["93", 0],
                "vae": ["10", 0],
                "start_image": ["80", 0],
                "clip_vision_output": ["79", 0]
            },
            "class_type": "HunyuanVideo15ImageToVideo",
            "_meta": {"title": "HunyuanVideo15ImageToVideo"}
        },
        "79": {
            "inputs": {
                "crop": "center",
                "clip_vision": ["81", 0],
                "image": ["80", 0]
            },
            "class_type": "CLIPVisionEncode",
            "_meta": {"title": "CLIP Vision Encode"}
        },
        "80": {
            "inputs": {
                "image": input_image
            },
            "class_type": "LoadImage",
            "_meta": {"title": "Load Image"}
        },
        "81": {
            "inputs": {
                "clip_name": "sigclip_vision_patch14_384.safetensors"
            },
            "class_type": "CLIPVisionLoader",
            "_meta": {"title": "Load CLIP Vision"}
        },
        "93": {
            "inputs": {
                "text": negative_prompt,
                "clip": ["11", 0]
            },
            "class_type": "CLIPTextEncode",
            "_meta": {"title": "CLIP Text Encode (Negative Prompt)"}
        },
        "101": {
            "inputs": {
                "fps": fps,
                "images": ["8", 0]
            },
            "class_type": "CreateVideo",
            "_meta": {"title": "Create Video"}
        },
        "102": {
            "inputs": {
                "filename_prefix": "video/hunyuan_video_1.5",
                "format": "auto",
                "codec": "h264",
                "video": ["101", 0]
            },
            "class_type": "SaveVideo",
            "_meta": {"title": "Save Video"}
        },
        "125": {
            "inputs": {
                "noise": ["127", 0],
                "guider": ["129", 0],
                "sampler": ["128", 0],
                "sigmas": ["126", 0],
                "latent_image": ["78", 2]
            },
            "class_type": "SamplerCustomAdvanced",
            "_meta": {"title": "SamplerCustomAdvanced"}
        },
        "126": {
            "inputs": {
                "scheduler": "simple",
                "steps": steps,
                "denoise": 1,
                "model": ["12", 0]
            },
            "class_type": "BasicScheduler",
            "_meta": {"title": "BasicScheduler"}
        },
        "127": {
            "inputs": {
                "noise_seed": seed
            },
            "class_type": "RandomNoise",
            "_meta": {"title": "RandomNoise"}
        },
        "128": {
            "inputs": {
                "sampler_name": "euler"
            },
            "class_type": "KSamplerSelect",
            "_meta": {"title": "KSamplerSelect"}
        },
        "129": {
            "inputs": {
                "cfg": cfg,
                "model": ["130", 0],
                "positive": ["78", 0],
                "negative": ["78", 1]
            },
            "class_type": "CFGGuider",
            "_meta": {"title": "CFGGuider"}
        },
        "130": {
            "inputs": {
                "shift": shift,
                "model": ["12", 0]
            },
            "class_type": "ModelSamplingSD3",
            "_meta": {"title": "ModelSamplingSD3"}
        }
    }
    
    return workflow


def handler(job):
    """
    RunPod Serverless Handler Function
    
    This is the main handler function that RunPod calls for each job.
    It receives a job dictionary with 'id' and 'input' fields.
    
    Expected input format:
    {
        "input": {
            "image": "base64_encoded_image",  # Optional if image_url provided
            "image_url": "https://url-to-image",  # Optional if image provided
            "workflow": {},  # Optional custom workflow
            "prompt": "text prompt",  # Optional
            "negative_prompt": "negative prompt",  # Optional
            "seed": 123,  # Optional
            "num_frames": 25,  # Optional, default 25
            "fps": 24,  # Optional, default 24
            "steps": 20,  # Optional, default 20
            "cfg": 1,  # Optional, default 1 (for distilled model)
            "width": 720,  # Optional, default 720
            "height": 1280,  # Optional, default 1280
            "shift": 7  # Optional, default 7
        }
    }
    
    Returns:
    - Success: {"status": "success", "prompt_id": str, "outputs": list}
    - Error: {"error": str}
    """
    print("=" * 60)
    print("HANDLER CALLED - NEW REQUEST RECEIVED")
    print(f"Job ID: {job.get('id', 'unknown')}")
    print("=" * 60)
    
    job_input = job.get("input", {})
    
    try:
        # Validate input
        image_input = job_input.get("image")
        image_url = job_input.get("image_url")
        
        if not image_input and not image_url:
            return {"error": "No image or image_url provided. Please provide either 'image' (base64) or 'image_url' (URL string)."}
        
        print(f"Processing job: {job.get('id', 'unknown')}")
        
        # Handle URL or base64 image
        if image_url:
            print(f"Downloading image from URL: {image_url}")
            try:
                response = requests.get(image_url, timeout=30)
                response.raise_for_status()
                image_data = response.content
            except requests.RequestException as e:
                return {"error": f"Failed to download image from URL: {str(e)}"}
        elif isinstance(image_input, str) and (image_input.startswith("http://") or image_input.startswith("https://")):
            # Fallback to image field if it's a URL
            print(f"Downloading image from URL (image field): {image_input}")
            try:
                response = requests.get(image_input, timeout=30)
                response.raise_for_status()
                image_data = response.content
            except requests.RequestException as e:
                return {"error": f"Failed to download image from URL: {str(e)}"}
        else:
            # Base64 encoded image
            image_data = image_input
        
        # Upload image to ComfyUI
        try:
            input_filename = upload_image(image_data)
            print(f"Uploaded image: {input_filename}")
        except Exception as e:
            return {"error": f"Failed to upload image: {str(e)}"}
        
        # Get or create workflow
        workflow = job_input.get("workflow")
        if not workflow:
            try:
                workflow = create_default_workflow(
                    input_image=input_filename,
                    prompt=job_input.get("prompt", ""),
                    negative_prompt=job_input.get("negative_prompt", ""),
                    seed=job_input.get("seed"),
                    num_frames=job_input.get("num_frames", 25),
                    fps=job_input.get("fps", 24),
                    steps=job_input.get("steps", 20),
                    cfg=job_input.get("cfg", 1),
                    width=job_input.get("width", 720),
                    height=job_input.get("height", 1280),
                    shift=job_input.get("shift", 7)
                )
            except Exception as e:
                return {"error": f"Failed to create workflow: {str(e)}"}
        
        # Queue the workflow
        print("Queueing workflow in ComfyUI...")
        try:
            queue_result = queue_prompt(workflow)
            
            if "error" in queue_result:
                return {"error": f"Failed to queue workflow: {queue_result['error']}"}
            
            prompt_id = queue_result.get("prompt_id")
            if not prompt_id:
                return {"error": "No prompt_id returned from ComfyUI"}
                
            print(f"Workflow queued with ID: {prompt_id}")
        except Exception as e:
            return {"error": f"Failed to queue workflow: {str(e)}"}
        
        # Wait for completion
        print("Waiting for workflow to complete...")
        try:
            history_entry = wait_for_completion(prompt_id, timeout=600)
        except TimeoutError as e:
            return {"error": f"Workflow execution timed out: {str(e)}"}
        except Exception as e:
            return {"error": f"Error during workflow execution: {str(e)}"}
        
        # Get output files
        try:
            output_files = get_output_files(history_entry)
            print(f"Generated {len(output_files)} output files")
            
            if not output_files:
                return {"error": "No output files generated"}
        except Exception as e:
            return {"error": f"Failed to get output files: {str(e)}"}
        
        # Prepare results
        results = []
        for output in output_files:
            try:
                file_data = get_file_as_base64(
                    output["filename"],
                    output["subfolder"],
                    output["type_name"]
                )
                
                if file_data:
                    results.append({
                        "type": output["type"],
                        "filename": output["filename"],
                        "data": file_data
                    })
                else:
                    print(f"Warning: Could not read file {output['filename']}")
            except Exception as e:
                print(f"Error reading output file {output.get('filename', 'unknown')}: {str(e)}")
                continue
        
        if not results:
            return {"error": "Failed to read any output files"}
        
        return {
            "status": "success",
            "prompt_id": prompt_id,
            "outputs": results
        }
        
    except Exception as e:
        print(f"Unhandled error in handler: {str(e)}")
        import traceback
        traceback.print_exc()
        return {"error": f"Internal error: {str(e)}"}


if __name__ == "__main__":
    print("=" * 60)
    print("INITIALIZING RUNPOD SERVERLESS WORKER")
    print("=" * 60)
    
    # Start ComfyUI server
    if not start_comfyui():
        print("Failed to start ComfyUI. Exiting.")
        sys.exit(1)
    
    try:
        # Start RunPod serverless worker
        print("Starting RunPod serverless worker...")
        print(f"Handler function: {handler}")
        print(f"Handler callable: {callable(handler)}")
        runpod.serverless.start({"handler": handler})
    except KeyboardInterrupt:
        print("Received shutdown signal")
    except Exception as e:
        print(f"Error starting serverless worker: {e}")
        import traceback
        traceback.print_exc()
    finally:
        stop_comfyui()
