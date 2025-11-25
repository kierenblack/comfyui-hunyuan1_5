# Updates Summary

## Changes Made

### 1. Updated `handler.py`
- ✅ Replaced placeholder workflow with actual Hunyuan 1.5 Video workflow structure from `video_workflow.json`
- ✅ Added `image_url` parameter support (in addition to base64 `image`)
- ✅ Updated workflow to use correct node structure:
  - VAELoader, DualCLIPLoader, UNETLoader
  - HunyuanVideo15ImageToVideo node
  - CLIPVisionEncode with proper CLIP Vision model
  - SamplerCustomAdvanced with CFGGuider
  - ModelSamplingSD3 with shift parameter
- ✅ Added support for all new parameters:
  - `negative_prompt`
  - `cfg` (default: 1 for distilled model)
  - `width` and `height` (default: 720x1280)
  - `shift` (default: 7)
  - Updated defaults: `num_frames=25`, `fps=24`, `steps=20`

### 2. Updated `example_workflow.json`
- ✅ Replaced with actual Hunyuan 1.5 workflow structure
- ✅ Added documentation of required models
- ✅ Updated parameter descriptions
- ✅ Matches the official workflow from Hunyuan repo

### 3. Updated `builder.sh`
- ✅ Changed model directory structure to match requirements:
  - `models/diffusion_models/` for UNet
  - `models/text_encoders/` for text encoders
  - `models/clip_vision/` for vision encoder
- ✅ Updated to download all 5 required models:
  - hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors
  - hunyuanvideo15_vae_fp16.safetensors
  - qwen_2.5_vl_7b_fp8_scaled.safetensors
  - byt5_small_glyphxl_fp16.safetensors
  - sigclip_vision_patch14_384.safetensors
- ✅ Updated environment variable names

### 4. Updated `.env.example`
- ✅ Added all 5 model URL environment variables
- ✅ Added link to Hugging Face model repository

### 5. Updated `README.md`
- ✅ Added `image_url` parameter documentation
- ✅ Updated API usage examples with both methods
- ✅ Updated input parameters table with all new parameters
- ✅ Corrected required models list with actual filenames
- ✅ Updated model download instructions
- ✅ Changed default values to match distilled model requirements

### 6. Updated `test_local.py`
- ✅ Enhanced with multiple test modes:
  - `--mode base64`: Test with base64 encoded image
  - `--mode url`: Test with image_url parameter
  - `--mode file`: Test with local image file
  - `--mode all`: Run all tests
- ✅ Added better error handling and display
- ✅ Demonstrates both `image` and `image_url` usage

## Key Features

### Image Input Methods
1. **Base64 encoded** - Pass image data directly in `image` field
2. **URL** - Pass image URL in `image_url` field (new!)
3. **Backward compatible** - `image` field also accepts URLs for compatibility

### Workflow Structure
The workflow now matches the official Hunyuan 1.5 implementation:
- Uses distilled FP8 model for faster inference
- Proper CLIP Vision encoding for image conditioning
- CFG scale of 1.0 (optimal for distilled model)
- Support for up to 129 frames
- Configurable dimensions and parameters

### Model Requirements
All 5 models are properly documented and can be:
- Auto-downloaded via environment variables
- Manually placed in directories
- Mounted via RunPod network volume (recommended)

## Testing

Run tests locally:
```bash
# Test with base64
python test_local.py --mode base64

# Test with URL
python test_local.py --mode url

# Test with local file
python test_local.py --mode file --image /path/to/image.png

# Run all tests
python test_local.py --mode all
```

## Deployment

The setup is ready for RunPod deployment with:
- Correct model paths and filenames
- Proper workflow structure
- Support for both image input methods
- All parameters from the official workflow
