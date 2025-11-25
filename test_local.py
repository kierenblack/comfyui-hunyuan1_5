"""
Test script for local development
"""
import requests
import json
import base64
import sys
import argparse

def test_with_base64():
    """Test the handler with base64 encoded image"""
    
    # Sample image (1x1 red pixel as base64 PNG)
    sample_image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
    
    test_input = {
        "input": {
            "image": f"data:image/png;base64,{sample_image}",
            "prompt": "cinematic motion, smooth animation, high quality",
            "negative_prompt": "blurry, low quality, distorted",
            "seed": 42,
            "num_frames": 25,
            "fps": 24,
            "steps": 20,
            "cfg": 1,
            "width": 720,
            "height": 1280
        }
    }
    
    print("Test 1: Using base64 encoded image")
    print("=" * 60)
    print(json.dumps(test_input, indent=2))
    
    return send_request(test_input)

def test_with_url():
    """Test the handler with image_url"""
    
    test_input = {
        "input": {
            "image_url": "https://picsum.photos/720/1280",  # Random placeholder image
            "prompt": "smooth cinematic movement, professional quality",
            "negative_prompt": "static, blurry, artifacts",
            "seed": 12345,
            "num_frames": 25,
            "fps": 24,
            "steps": 20
        }
    }
    
    print("\nTest 2: Using image_url parameter")
    print("=" * 60)
    print(json.dumps(test_input, indent=2))
    
    return send_request(test_input)

def test_with_local_file(image_path):
    """Test with a local image file"""
    
    try:
        with open(image_path, "rb") as f:
            image_data = base64.b64encode(f.read()).decode()
        
        test_input = {
            "input": {
                "image": image_data,
                "prompt": "cinematic motion, smooth transitions",
                "num_frames": 25,
                "fps": 24,
                "steps": 20
            }
        }
        
        print(f"\nTest 3: Using local file: {image_path}")
        print("=" * 60)
        print("(Image data truncated for display)")
        
        return send_request(test_input)
        
    except FileNotFoundError:
        print(f"Error: File not found: {image_path}")
        return None
    except Exception as e:
        print(f"Error reading file: {e}")
        return None

def send_request(test_input):
    """Send request to the handler"""
    
    # If running locally with docker-compose
    url = "http://localhost:8000"
    
    try:
        print("\nSending request...")
        response = requests.post(url, json=test_input, timeout=600)
        result = response.json()
        
        print("\nResponse:")
        print(json.dumps(result, indent=2))
        
        return result
    except requests.exceptions.ConnectionError:
        print(f"Error: Could not connect to {url}")
        print("Make sure the server is running with: docker-compose up")
        return None
    except requests.exceptions.Timeout:
        print("Error: Request timed out")
        return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description="Test ComfyUI Hunyuan handler")
    parser.add_argument("--mode", choices=["base64", "url", "file", "all"], 
                       default="all", help="Test mode")
    parser.add_argument("--image", type=str, help="Path to local image file (for file mode)")
    
    args = parser.parse_args()
    
    if args.mode == "base64":
        test_with_base64()
    elif args.mode == "url":
        test_with_url()
    elif args.mode == "file":
        if not args.image:
            print("Error: --image parameter required for file mode")
            sys.exit(1)
        test_with_local_file(args.image)
    else:  # all
        test_with_base64()
        test_with_url()

if __name__ == "__main__":
    main()
