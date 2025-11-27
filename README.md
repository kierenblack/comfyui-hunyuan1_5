[![Runpod](https://api.runpod.io/badge/kierenblack/comfyui-hunyuan1_5)](https://console.runpod.io/hub/kierenblack/comfyui-hunyuan1_5)

# ComfyUI Hunyuan 1.5 Video - RunPod Serverless

This repository contains a complete RunPod serverless deployment for ComfyUI with Hunyuan 1.5 Video support, enabling image-to-video (img2vid) generation.

## Features

- 🎬 Image-to-video generation using Hunyuan 1.5 Video models
- 🚀 RunPod serverless deployment ready
- 🐳 Docker containerized for easy deployment
- 🔧 ComfyUI with custom nodes pre-configured
- 📦 Automatic model downloading and setup
- 🎯 Simple REST API interface

## ⚠️ Important: Handler Fixes Applied

**Recent changes to fix handler not being called issue:**
1. ✅ Removed invalid `--rp_serve_api` flag from Dockerfile
2. ✅ Added comprehensive debug logging
3. ✅ Created test scripts for local verification

**You MUST rebuild and redeploy for fixes to take effect!**

See [DEPLOYMENT.md](DEPLOYMENT.md) for deployment instructions or run:
```bash
./build_and_deploy.sh
```

## Quick Start

### Prerequisites

- RunPod account with serverless endpoint setup
- Docker installed (for local testing)
- Docker Hub account (for deployment)
- NVIDIA GPU with CUDA support (locally) or RunPod GPU
- Hunyuan 1.5 Video model files (see Model Setup)

### Local Testing with Docker Compose

1. **Clone the repository**
```bash
git clone <your-repo-url>
cd comfyui-hunyuan1_5
```

2. **Configure environment variables** (optional)
```bash
cp .env.example .env
# Edit .env with your model URLs
```

3. **Build and run**
```bash
docker-compose up --build
```

4. **Access ComfyUI**
- ComfyUI UI: http://localhost:8188
- RunPod Handler: http://localhost:8000

### Deploy to RunPod

#### Method 1: Using RunPod Template

1. **Build and push Docker image**
```bash
docker build -t your-dockerhub-username/comfyui-hunyuan:latest .
docker push your-dockerhub-username/comfyui-hunyuan:latest
```

2. **Create RunPod Serverless Endpoint**
   - Go to RunPod Serverless
   - Create new template with your Docker image
   - Set container disk size to at least 30GB
   - Configure GPU (recommend RTX 4090 or A100)

3. **Set environment variables** (optional)
   - `HUNYUAN_UNET_URL`: Direct download URL for UNet model
   - `HUNYUAN_VAE_URL`: Direct download URL for VAE model
   - `CLIP1_URL`: Direct download URL for Qwen CLIP model
   - `CLIP2_URL`: Direct download URL for ByT5 CLIP model
   - `CLIP_VISION_URL`: Direct download URL for CLIP Vision model

#### Method 2: Network Volume (Recommended for faster cold starts)

1. Create a network volume in RunPod
2. Upload models to the network volume with proper structure:
   - `/diffusion_models/` for UNet
   - `/text_encoders/` for CLIP models
   - `/vae/` for VAE
   - `/clip_vision/` for CLIP Vision
3. Mount the network volume to `/app/ComfyUI/models` in your endpoint
4. Deploy using your Docker image

## Model Setup

### Required Models

Hunyuan 1.5 Video requires the following models (download from [Hugging Face](https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged)):

1. **UNet Model**: `hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors`
   - Place in: `models/diffusion_models/`

2. **VAE**: `hunyuanvideo15_vae_fp16.safetensors`
   - Place in: `models/vae/`

3. **CLIP Text Encoders**:
   - `qwen_2.5_vl_7b_fp8_scaled.safetensors` → `models/text_encoders/`
   - `byt5_small_glyphxl_fp16.safetensors` → `models/text_encoders/`

4. **CLIP Vision**: `sigclip_vision_patch14_384.safetensors`
   - Place in: `models/clip_vision/`

### Download Options

**Option 1: Environment Variables**
Set environment variables with direct download links:
- `HUNYUAN_UNET_URL`
- `HUNYUAN_VAE_URL`
- `CLIP1_URL`
- `CLIP2_URL`
- `CLIP_VISION_URL`

**Option 2: Manual Download**
Download models from [Hugging Face](https://huggingface.co/tencent/HunyuanVideo) and place them in the appropriate directories before building the image.

**Option 3: Network Volume (Recommended)**
Upload models to RunPod network volume and mount it to `/app/ComfyUI/models`. This provides the fastest cold starts.

## API Usage

### Request Format

```python
import requests
import base64

# Option 1: Using image_url (recommended for URLs)
response = requests.post(
    "https://api.runpod.ai/v2/YOUR_ENDPOINT_ID/runsync",
    headers={
        "Authorization": "Bearer YOUR_API_KEY"
    },
    json={
        "input": {
            "image_url": "https://example.com/image.png",
            "prompt": "cinematic motion, smooth animation, high quality",
            "negative_prompt": "blurry, distorted, low quality",
            "seed": 42,
            "num_frames": 25,
            "fps": 24,
            "steps": 20,
            "cfg": 1,
            "width": 720,
            "height": 1280
        }
    }
)

# Option 2: Using base64 encoded image
with open("input_image.png", "rb") as f:
    image_data = base64.b64encode(f.read()).decode()

response = requests.post(
    "https://api.runpod.ai/v2/YOUR_ENDPOINT_ID/runsync",
    headers={
        "Authorization": "Bearer YOUR_API_KEY"
    },
    json={
        "input": {
            "image": image_data,
            "prompt": "cinematic motion, smooth animation, high quality",
            "num_frames": 25,
            "fps": 24,
            "steps": 20
        }
    }
)

result = response.json()
```

### Input Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image` | string | null | Base64 encoded image (required if `image_url` not provided) |
| `image_url` | string | null | URL to image (required if `image` not provided) |
| `prompt` | string | "" | Text description of desired motion |
| `negative_prompt` | string | "" | Negative prompt (things to avoid) |
| `seed` | integer | random | Random seed for reproducibility |
| `num_frames` | integer | 25 | Number of frames (25-129) |
| `fps` | integer | 24 | Frames per second |
| `steps` | integer | 20 | Sampling steps (default for distilled model) |
| `cfg` | float | 1.0 | CFG scale (1.0 for distilled model) |
| `width` | integer | 720 | Output video width |
| `height` | integer | 1280 | Output video height |
| `shift` | integer | 7 | Model sampling shift parameter |
| `workflow` | object | null | Custom ComfyUI workflow (optional) |

### Response Format

```json
{
  "status": "success",
  "prompt_id": "abc123",
  "outputs": [
    {
      "type": "video",
      "filename": "hunyuan_video_00001.mp4",
      "data": "base64_encoded_video_data"
    }
  ]
}
```

## Custom Workflows

You can provide your own ComfyUI workflow JSON:

```python
with open("example_workflow.json") as f:
    workflow = json.load(f)

response = requests.post(endpoint, json={
    "input": {
        "image": image_data,
        "workflow": workflow["workflow"]
    }
})
```

See `example_workflow.json` for a template.

## Project Structure

```
.
├── Dockerfile              # Docker image definition
├── docker-compose.yml      # Local testing setup
├── handler.py              # RunPod serverless handler
├── builder.sh              # Model download and setup script
├── requirements.txt        # Python dependencies
├── example_workflow.json   # Sample ComfyUI workflow
├── test_local.py          # Local testing script
├── .env.example           # Environment variables template
├── .gitignore             # Git ignore rules
└── README.md              # This file
```

## Custom Nodes

This deployment includes:

- **ComfyUI-HunyuanVideoWrapper**: Hunyuan Video node implementation
- **ComfyUI-VideoHelperSuite**: Video processing utilities
- **ComfyUI-Manager**: Node and model management

## Troubleshooting

### Handler Not Being Called

**Symptoms:** Endpoint starts successfully but requests never reach handler function

**Solution:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed debug guide

**Quick checks:**
1. Did you rebuild and redeploy after recent fixes? Run `./build_and_deploy.sh`
2. Are you testing with the correct endpoint? Use `/runsync` or `/run` path
3. Check logs for "INITIALIZING RUNPOD SERVERLESS WORKER" message
4. Check logs for "HANDLER CALLED - NEW REQUEST RECEIVED" when sending requests
5. Test locally first: `python handler.py` then `python test_runpod_local.py sync`

### Out of Memory Errors

- Reduce `num_frames` (try 25 instead of 49)
- Use a GPU with more VRAM
- Enable CPU offloading in the workflow

### Slow Cold Starts

- Use RunPod network volume for models (reduces to 30-60 seconds)
- Pre-bake models into Docker image (increases image size significantly)
- Use keep-alive workers

### Model Not Found

- Verify models are in correct directories
- Check `builder.sh` output for download errors
- Manually upload models to network volume
- Check network volume is mounted correctly

### Video Quality Issues

- Increase `steps` (30-50 recommended)
- Adjust `cfg` scale (6-8 recommended, or 1.0 for distilled model)
- Provide detailed prompts
- Ensure input image is high quality
- Use higher resolution input images

## Performance Tips

1. **Cold Start Optimization**
   - Use network volumes for models
   - Keep workers warm with traffic
   - Pre-download models during build

2. **Generation Speed**
   - RTX 4090: ~5-10s per second of video
   - A100: ~3-7s per second of video
   - Reduce frames for faster generation

3. **Cost Optimization**
   - Batch requests when possible
   - Use appropriate GPU tier
   - Enable autoscaling

## Development

### Local Testing

```bash
# Build the image
docker-compose build

# Run the container
docker-compose up

# Test the handler
python test_local.py
```

### Modifying Workflows

1. Edit `example_workflow.json`
2. Test in ComfyUI UI (http://localhost:8188)
3. Export workflow and update JSON
4. Test via handler API

## License

This project is provided as-is for use with RunPod serverless deployments.

## Credits

- ComfyUI: https://github.com/comfyanonymous/ComfyUI
- Hunyuan Video: Tencent Hunyuan
- ComfyUI-HunyuanVideoWrapper: https://github.com/kijai/ComfyUI-HunyuanVideoWrapper

## Support

For issues and questions:
- Open an issue in this repository
- Check ComfyUI documentation
- Visit RunPod community forums

## Changelog

### v1.0.0
- Initial release
- ComfyUI with Hunyuan 1.5 Video support
- RunPod serverless handler
- Docker deployment ready
