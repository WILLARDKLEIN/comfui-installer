#!/bin/bash
# Script to automatically detect NVIDIA GPU and start ComfyUI container

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check for nvidia-smi
check_nvidia_smi() {
  if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA drivers detected${NC}"
    return 0
  else
    echo -e "${RED}✗ NVIDIA drivers not found${NC}"
    return 1
  fi
}

# Function to check for nvidia-container-toolkit
check_nvidia_docker() {
  if docker info 2>/dev/null | grep -i nvidia > /dev/null; then
    echo -e "${GREEN}✓ NVIDIA Container Toolkit detected${NC}"
    return 0
  else
    echo -e "${RED}✗ NVIDIA Container Toolkit not found${NC}"
    return 1
  fi
}

# Function to test GPU access in Docker
test_gpu_docker() {
  echo -e "${BLUE}Testing GPU access in Docker...${NC}"
  if docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ GPU access in Docker confirmed${NC}"
    return 0
  else
    echo -e "${RED}✗ GPU access in Docker failed${NC}"
    return 1
  fi
}

# Function to create .env file
create_env_file() {
  if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cat > .env << EOF
# Backblaze B2 Settings
B2_APPLICATION_KEY_ID=your_app_key_id
B2_APPLICATION_KEY=your_app_key
B2_BUCKET_NAME=your_bucket_name

# Rclone Settings
B2_RCLONE_TRANSFERS=4
B2_RCLONE_CHECKERS=8

# GPU Settings (comma-separated list of GPU indices or 'all')
CUDA_VISIBLE_DEVICES=all
GPU_COUNT=all

# PyTorch Memory Management
PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
EOF
    echo -e "${YELLOW}Please edit .env file with your Backblaze B2 credentials${NC}"
  fi
}

# Main execution
echo -e "${BLUE}=== ComfyUI Container Setup ===${NC}"

# Create directories if they don't exist
mkdir -p ./models ./output ./input
create_env_file

# Check for docker-compose
if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
  echo -e "${RED}Error: Docker Compose not found. Please install Docker and Docker Compose.${NC}"
  exit 1
fi

# Detect Docker Compose command
if command -v docker-compose &> /dev/null; then
  DOCKER_COMPOSE="docker-compose"
else
  DOCKER_COMPOSE="docker compose"
fi

# Check GPU availability
GPU_AVAILABLE=false
if check_nvidia_smi && check_nvidia_docker && test_gpu_docker; then
  GPU_AVAILABLE=true
  echo -e "${GREEN}=== GPU setup complete, starting ComfyUI with GPU support ===${NC}"
else
  echo -e "${YELLOW}=== GPU not available, starting ComfyUI in CPU-only mode ===${NC}"
  echo -e "${YELLOW}Note: ComfyUI will be much slower without GPU acceleration${NC}"
fi

# Pull the latest container image
echo -e "${BLUE}Pulling latest ComfyUI container...${NC}"
docker pull wklein92/comfyui:rclone

# Start the container
if [ "$GPU_AVAILABLE" = true ]; then
  # Start with GPU support
  $DOCKER_COMPOSE -f docker-compose.robust.yml up -d
else
  # Start in CPU-only mode
  $DOCKER_COMPOSE -f docker-compose.robust.yml --profile cpu-only up -d
fi

# Display access information
echo -e "${GREEN}=== ComfyUI is starting! ===${NC}"
echo -e "${BLUE}Access ComfyUI at http://localhost:8188${NC}"
echo -e "${YELLOW}To stop ComfyUI, run: docker-compose -f docker-compose.robust.yml down${NC}"

# Check container startup
echo -e "${BLUE}Checking container status...${NC}"
sleep 5
$DOCKER_COMPOSE -f docker-compose.robust.yml ps 