#!/bin/bash
# Quick build and push script for RunPod deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ComfyUI Hunyuan 1.5 - Build & Deploy${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get Docker Hub username
read -p "Enter your Docker Hub username: " DOCKER_USER

if [ -z "$DOCKER_USER" ]; then
    echo -e "${RED}Error: Docker Hub username required${NC}"
    exit 1
fi

# Get version tag (optional)
read -p "Enter version tag (default: latest): " VERSION
VERSION=${VERSION:-latest}

IMAGE_NAME="${DOCKER_USER}/comfyui-hunyuan"
FULL_TAG="${IMAGE_NAME}:${VERSION}"

echo ""
echo -e "${YELLOW}Building image: ${FULL_TAG}${NC}"
echo ""

# Build
docker build -t "${FULL_TAG}" .

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Build successful${NC}"
echo ""

# Ask if want to push
read -p "Push to Docker Hub? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Logging in to Docker Hub...${NC}"
    docker login
    
    echo ""
    echo -e "${YELLOW}Pushing ${FULL_TAG}...${NC}"
    docker push "${FULL_TAG}"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Push failed!${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✓ Push successful${NC}"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Docker image: ${FULL_TAG}"
    echo ""
    echo "Next steps:"
    echo "1. Go to RunPod console"
    echo "2. Update your endpoint to use: ${FULL_TAG}"
    echo "3. Save and redeploy"
    echo "4. Check logs for: 'INITIALIZING RUNPOD SERVERLESS WORKER'"
    echo "5. Test with: python test_runpod_local.py"
    echo ""
else
    echo ""
    echo -e "${YELLOW}Image built but not pushed${NC}"
    echo ""
    echo "To push later:"
    echo "  docker push ${FULL_TAG}"
    echo ""
    echo "To test locally:"
    echo "  docker run --rm -it --gpus all -p 8188:8188 -p 8000:8000 ${FULL_TAG}"
    echo ""
fi
