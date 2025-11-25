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
    
    # Set default URLs from Hugging Face if not provided
    : ${HUNYUAN_UNET_URL:="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/diffusion_models/hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors"}
    : ${HUNYUAN_VAE_URL:="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/vae/hunyuanvideo15_vae_fp16.safetensors"}
    : ${CLIP1_URL:="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"}
    : ${CLIP2_URL:="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors"}
    : ${CLIP_VISION_URL:="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/clip_vision/sigclip_vision_patch14_384.safetensors"}
    
    echo "📥 Downloading models from Hugging Face..."
    echo "   This may take a while (~30GB total download)"
    echo ""
    
    # 1. Main UNet Model (distilled FP8)
    echo "Downloading Hunyuan Video UNet model (~16GB)..."
    mkdir -p "${MODELS_DIR}/diffusion_models"
    download_with_retry "$HUNYUAN_UNET_URL" "${MODELS_DIR}/diffusion_models/hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors"
    
    # 2. VAE Model
    echo "Downloading VAE model (~2GB)..."
    download_with_retry "$HUNYUAN_VAE_URL" "${MODELS_DIR}/vae/hunyuanvideo15_vae_fp16.safetensors"
    
    # 3. CLIP Text Encoders
    echo "Downloading CLIP model 1 (Qwen, ~8GB)..."
    download_with_retry "$CLIP1_URL" "${MODELS_DIR}/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
    
    echo "Downloading CLIP model 2 (ByT5, ~500MB)..."
    download_with_retry "$CLIP2_URL" "${MODELS_DIR}/text_encoders/byt5_small_glyphxl_fp16.safetensors"
    
    # 4. CLIP Vision Model
    echo "Downloading CLIP Vision model (~1GB)..."
    download_with_retry "$CLIP_VISION_URL" "${MODELS_DIR}/clip_vision/sigclip_vision_patch14_384.safetensors"
    
    echo ""
    echo "✅ All models downloaded successfully!"
    
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
