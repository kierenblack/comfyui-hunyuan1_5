#!/bin/bash
# Builder script to download models and setup ComfyUI environment
set -e

echo "=========================================="
echo "Starting ComfyUI setup for Hunyuan 1.5 Video"
echo "=========================================="

COMFYUI_PATH="/app/ComfyUI"
MODELS_DIR="${COMFYUI_PATH}/models"

# Create necessary directories based on Hunyuan 1.5 requirements
mkdir -p "${MODELS_DIR}/diffusion_models"
mkdir -p "${MODELS_DIR}/text_encoders"
mkdir -p "${MODELS_DIR}/vae"
mkdir -p "${MODELS_DIR}/unet"
mkdir -p "${MODELS_DIR}/clip_vision"

# Function to download file with retries
download_with_retry() {
    local url=$1
    local output=$2
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Downloading (attempt $attempt/$max_attempts): $url"
        if wget -c --no-check-certificate -O "$output" "$url"; then
            echo "Download successful: $output"
            return 0
        else
            echo "Download failed, retrying..."
            attempt=$((attempt + 1))
            sleep 5
        fi
    done
    
    echo "Failed to download after $max_attempts attempts: $url"
    return 1
}

# Check if models already exist (for faster rebuilds)
if [ -f "${MODELS_DIR}/diffusion_models/.downloaded" ]; then
    echo "Models already downloaded, skipping..."
else
    echo "=========================================="
    echo "Downloading Hunyuan Video 1.5 Models"
    echo "=========================================="
    
    # Note: Set these environment variables with actual model URLs
    # Models required by the workflow:
    
    # 1. Main UNet Model (distilled FP8)
    if [ ! -z "$HUNYUAN_UNET_URL" ]; then
        echo "Downloading Hunyuan Video UNet model..."
        mkdir -p "${MODELS_DIR}/diffusion_models"
        download_with_retry "$HUNYUAN_UNET_URL" "${MODELS_DIR}/diffusion_models/hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors"
    else
        echo "⚠️  HUNYUAN_UNET_URL not set."
        echo "   Required: hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors"
        echo "   Place in: ${MODELS_DIR}/diffusion_models/"
    fi
    
    # 2. VAE Model
    if [ ! -z "$HUNYUAN_VAE_URL" ]; then
        echo "Downloading VAE model..."
        download_with_retry "$HUNYUAN_VAE_URL" "${MODELS_DIR}/vae/hunyuanvideo15_vae_fp16.safetensors"
    else
        echo "⚠️  HUNYUAN_VAE_URL not set."
        echo "   Required: hunyuanvideo15_vae_fp16.safetensors"
        echo "   Place in: ${MODELS_DIR}/vae/"
    fi
    
    # 3. CLIP Text Encoders
    if [ ! -z "$CLIP1_URL" ]; then
        echo "Downloading CLIP model 1 (Qwen)..."
        download_with_retry "$CLIP1_URL" "${MODELS_DIR}/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
    else
        echo "⚠️  CLIP1_URL not set."
        echo "   Required: qwen_2.5_vl_7b_fp8_scaled.safetensors"
        echo "   Place in: ${MODELS_DIR}/text_encoders/"
    fi
    
    if [ ! -z "$CLIP2_URL" ]; then
        echo "Downloading CLIP model 2 (ByT5)..."
        download_with_retry "$CLIP2_URL" "${MODELS_DIR}/text_encoders/byt5_small_glyphxl_fp16.safetensors"
    else
        echo "⚠️  CLIP2_URL not set."
        echo "   Required: byt5_small_glyphxl_fp16.safetensors"
        echo "   Place in: ${MODELS_DIR}/text_encoders/"
    fi
    
    # 4. CLIP Vision Model
    if [ ! -z "$CLIP_VISION_URL" ]; then
        echo "Downloading CLIP Vision model..."
        download_with_retry "$CLIP_VISION_URL" "${MODELS_DIR}/clip_vision/sigclip_vision_patch14_384.safetensors"
    else
        echo "⚠️  CLIP_VISION_URL not set."
        echo "   Required: sigclip_vision_patch14_384.safetensors"
        echo "   Place in: ${MODELS_DIR}/clip_vision/"
    fi
    
    # Mark as downloaded
    mkdir -p "${MODELS_DIR}/diffusion_models"
    touch "${MODELS_DIR}/diffusion_models/.downloaded"
fi

echo "=========================================="
echo "Setting up custom nodes"
echo "=========================================="

# Update ComfyUI Manager if it exists
if [ -d "${COMFYUI_PATH}/custom_nodes/ComfyUI-Manager" ]; then
    echo "Updating ComfyUI Manager..."
    cd "${COMFYUI_PATH}/custom_nodes/ComfyUI-Manager"
    git pull || echo "Failed to update ComfyUI Manager, continuing..."
fi

# Update Hunyuan Video Wrapper
if [ -d "${COMFYUI_PATH}/custom_nodes/ComfyUI-HunyuanVideoWrapper" ]; then
    echo "Updating Hunyuan Video Wrapper..."
    cd "${COMFYUI_PATH}/custom_nodes/ComfyUI-HunyuanVideoWrapper"
    git pull || echo "Failed to update Hunyuan Video Wrapper, continuing..."
    
    # Install/update dependencies
    if [ -f requirements.txt ]; then
        pip install -r requirements.txt
    fi
fi

# Install Video Helper Suite for video handling
if [ ! -d "${COMFYUI_PATH}/custom_nodes/ComfyUI-VideoHelperSuite" ]; then
    echo "Installing Video Helper Suite..."
    cd "${COMFYUI_PATH}/custom_nodes"
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
    cd ComfyUI-VideoHelperSuite
    if [ -f requirements.txt ]; then
        pip install -r requirements.txt
    fi
fi

echo "=========================================="
echo "Checking Python environment"
echo "=========================================="
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda if torch.cuda.is_available() else \"N/A\"}')"

echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Model locations:"
echo "  UNet: ${MODELS_DIR}/diffusion_models/hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors"
echo "  VAE: ${MODELS_DIR}/vae/hunyuanvideo15_vae_fp16.safetensors"
echo "  CLIP 1: ${MODELS_DIR}/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
echo "  CLIP 2: ${MODELS_DIR}/text_encoders/byt5_small_glyphxl_fp16.safetensors"
echo "  CLIP Vision: ${MODELS_DIR}/clip_vision/sigclip_vision_patch14_384.safetensors"
echo ""
echo "To download models automatically, set these environment variables:"
echo "  - HUNYUAN_UNET_URL: URL to UNet model"
echo "  - HUNYUAN_VAE_URL: URL to VAE model"
echo "  - CLIP1_URL: URL to Qwen CLIP model"
echo "  - CLIP2_URL: URL to ByT5 CLIP model"
echo "  - CLIP_VISION_URL: URL to CLIP Vision model"
echo ""
echo "Or manually place model files in the respective directories."
echo "Models can be downloaded from Hugging Face: huggingface.co/tencent/HunyuanVideo"
echo "=========================================="

# Don't exit the container, just finish the script
exit 0
