# Dockerfile for ComfyUI with Hunyuan 1.5 Video Support on RunPod Serverless
# Base image: Latest PyTorch with CUDA 12.6 on Ubuntu 22.04
FROM runpod/pytorch:2.5.1-py3.11-cuda12.6.3-devel-ubuntu22.04

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI

# Install ComfyUI requirements
WORKDIR /app/ComfyUI
RUN pip install --no-cache-dir -r requirements.txt

# Install additional dependencies for Hunyuan Video
RUN pip install --no-cache-dir \
    opencv-python \
    imageio \
    imageio-ffmpeg \
    accelerate \
    transformers \
    diffusers \
    sentencepiece \
    protobuf \
    safetensors \
    einops \
    omegaconf \
    kornia \
    timm

# Install ComfyUI Manager (optional but recommended)
WORKDIR /app/ComfyUI/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# Clone Hunyuan Video custom nodes
RUN git clone https://github.com/kijai/ComfyUI-HunyuanVideoWrapper.git

# Install dependencies for Hunyuan Video wrapper
WORKDIR /app/ComfyUI/custom_nodes/ComfyUI-HunyuanVideoWrapper
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Copy application files
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY handler.py .
COPY builder.sh .
RUN chmod +x builder.sh

# Create directories for models and outputs
RUN mkdir -p /app/ComfyUI/models/checkpoints \
    /app/ComfyUI/models/text_encoders \
    /app/ComfyUI/models/vae \
    /app/ComfyUI/models/diffusion_models \
    /app/ComfyUI/models/clip_vision \
    /app/ComfyUI/input \
    /app/ComfyUI/output

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV COMFYUI_PATH=/app/ComfyUI

# Expose port for ComfyUI
EXPOSE 8188

# Run builder script on container start to download models
# For RunPod, handler.py will run automatically
# For local testing, keep the container alive
CMD ["/bin/bash", "-c", "./builder.sh && python handler.py --rp_serve_api"]
