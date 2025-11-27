#!/bin/bash
# Quick build script for local testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ComfyUI Hunyuan 1.5 - Local Build${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

IMAGE_NAME="comfyui-hunyuan-test"

echo -e "${YELLOW}Building image for local testing: ${IMAGE_NAME}${NC}"
echo ""

# Build
docker build -t "${IMAGE_NAME}" .

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Build successful!${NC}"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Local Test Image Built${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To test locally:"
echo "  docker run --rm -it --gpus all -p 8188:8188 -p 8000:8000 ${IMAGE_NAME}"
echo ""
echo "For deployment:"
echo "1. Push your code to GitHub"
echo "2. In RunPod, create endpoint from GitHub repo"
echo "3. RunPod will build the Docker image automatically"
echo "4. Check logs for: 'INITIALIZING RUNPOD SERVERLESS WORKER'"
echo ""
