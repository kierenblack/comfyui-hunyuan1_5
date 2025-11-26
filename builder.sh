#!/bin/bash
# Builder script to download models and setup ComfyUI environment
set -e

echo "=========================================="
echo "Starting ComfyUI setup for Hunyuan 1.5 Video"
echo "=========================================="

COMFYUI_PATH="/app/ComfyUI"

# Check if RunPod network volume is mounted
NETWORK_VOLUME=""
if [ -d "/runpod-volume" ]; then
    NETWORK_VOLUME="/runpod-volume"
    echo "✓ Network volume detected at: /runpod-volume"
else
    echo "⚠ No network volume detected at /runpod-volume"
fi

# Always use ComfyUI's models directory
MODELS_DIR="${COMFYUI_PATH}/models"

# Create necessary directories
mkdir -p "${MODELS_DIR}/diffusion_models"
mkdir -p "${MODELS_DIR}/text_encoders"
mkdir -p "${MODELS_DIR}/vae"
mkdir -p "${MODELS_DIR}/unet"
mkdir -p "${MODELS_DIR}/clip_vision"

# If network volume exists, create same structure there
if [ -n "$NETWORK_VOLUME" ]; then
    mkdir -p "${NETWORK_VOLUME}/diffusion_models"
    mkdir -p "${NETWORK_VOLUME}/text_encoders"
    mkdir -p "${NETWORK_VOLUME}/vae"
    mkdir -p "${NETWORK_VOLUME}/clip_vision"
fi

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

# Set default URLs from Hugging Face if not provided
: ${HUNYUAN_UNET_URL:="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/diffusion_models/hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors"}
: ${HUNYUAN_VAE_URL:="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/vae/hunyuanvideo15_vae_fp16.safetensors"}
: ${CLIP1_URL:="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"}
: ${CLIP2_URL:="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors"}
: ${CLIP_VISION_URL:="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/clip_vision/sigclip_vision_patch14_384.safetensors"}

echo "=========================================="
echo "Checking and downloading models"
echo "=========================================="

# Function to check and download model if needed
download_model_if_needed() {
    local url=$1
    local filename=$2
    local subdir=$3
    local name=$4
    
    local comfyui_path="${MODELS_DIR}/${subdir}/${filename}"
    local network_path="${NETWORK_VOLUME}/${subdir}/${filename}"
    
    # Check if model exists in network volume first
    if [ -n "$NETWORK_VOLUME" ] && [ -f "$network_path" ]; then
        echo "✓ $name found in network volume, copying to ComfyUI..."
        cp "$network_path" "$comfyui_path"
        return 0
    fi
    
    # Check if model already exists in ComfyUI
    if [ -f "$comfyui_path" ]; then
        echo "✓ $name already exists in ComfyUI"
        # Copy to network volume for next time
        if [ -n "$NETWORK_VOLUME" ]; then
            echo "  Saving to network volume for future use..."
            cp "$comfyui_path" "$network_path"
        fi
        return 0
    fi
    
    # Download to ComfyUI and save to network volume
    echo "Downloading $name..."
    mkdir -p "$(dirname "$comfyui_path")"
    if download_with_retry "$url" "$comfyui_path"; then
        if [ -n "$NETWORK_VOLUME" ]; then
            echo "  Saving to network volume..."
            cp "$comfyui_path" "$network_path"
        fi
    fi
}

# Download each model if it doesn't exist
download_model_if_needed "$HUNYUAN_UNET_URL" "hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors" "diffusion_models" "Hunyuan Video UNet model (~16GB)"
download_model_if_needed "$HUNYUAN_VAE_URL" "hunyuanvideo15_vae_fp16.safetensors" "vae" "VAE model (~2GB)"
download_model_if_needed "$CLIP1_URL" "qwen_2.5_vl_7b_fp8_scaled.safetensors" "text_encoders" "CLIP model 1 (Qwen, ~8GB)"
download_model_if_needed "$CLIP2_URL" "byt5_small_glyphxl_fp16.safetensors" "text_encoders" "CLIP model 2 (ByT5, ~500MB)"
download_model_if_needed "$CLIP_VISION_URL" "sigclip_vision_patch14_384.safetensors" "clip_vision" "CLIP Vision model (~1GB)"

echo ""
echo "✅ All models ready!"

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
