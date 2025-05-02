#!/bin/bash
# ComfyUI All-in-One Installer Script
# This script sets up ComfyUI with GPU support in one command

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print banner
echo -e "${CYAN}"
echo "  ______              __      _   _ ___    _____           __        ____         "
echo " / ____/___  ____ _/ _|_   _| | | |_ _|  |_   _|__  ___ / _|____  / / /__  _____"
echo "| |   / __ \/ __ \| |_| | | | | | || |     | |/ _ \/ __| |_|_  / / / / _ \/ ___/"
echo "| |__| (_) | | | |  _| |_| | |_| || |     | |  __/\__ \  _|/ /_/ / /  __/ /    "
echo " \____\____/|_| |_|_|  \__, |\___/|___|    |_|\___||___/_|/___/_/_/\___/_/     "
echo "                       |___/                                                     "
echo -e "${NC}"

# Function to install NVIDIA drivers on Linux
install_nvidia_drivers() {
  echo -e "${BLUE}Checking for NVIDIA drivers...${NC}"
  if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA drivers already installed${NC}"
    return 0
  fi

  echo -e "${YELLOW}Installing NVIDIA drivers...${NC}"
  
  # Detect distribution
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case $ID in
      ubuntu|debian|linuxmint)
        sudo apt-get update
        sudo apt-get install -y nvidia-driver-535
        ;;
      fedora|centos|rhel)
        sudo dnf install -y akmod-nvidia
        ;;
      *)
        echo -e "${RED}Unsupported distribution: $ID${NC}"
        echo -e "${YELLOW}Please install NVIDIA drivers manually according to your distribution's documentation${NC}"
        return 1
        ;;
    esac
  else
    echo -e "${RED}Could not detect Linux distribution${NC}"
    echo -e "${YELLOW}Please install NVIDIA drivers manually${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✓ NVIDIA drivers installed. Please reboot your system before continuing.${NC}"
  echo -e "${YELLOW}After reboot, please run this script again.${NC}"
  exit 0
}

# Function to install Docker
install_docker() {
  echo -e "${BLUE}Checking for Docker...${NC}"
  if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker already installed${NC}"
  else
    echo -e "${YELLOW}Installing Docker...${NC}"
    
    # Detect distribution
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case $ID in
        ubuntu|debian|linuxmint)
          sudo apt-get update
          sudo apt-get install -y ca-certificates curl gnupg
          sudo install -m 0755 -d /etc/apt/keyrings
          curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
          sudo chmod a+r /etc/apt/keyrings/docker.gpg
          echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          sudo apt-get update
          sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
          ;;
        fedora)
          sudo dnf -y install dnf-plugins-core
          sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
          sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
          ;;
        centos|rhel)
          sudo yum install -y yum-utils
          sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
          sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
          ;;
        *)
          echo -e "${RED}Unsupported distribution: $ID${NC}"
          echo -e "${YELLOW}Please install Docker manually according to your distribution's documentation${NC}"
          return 1
          ;;
      esac
      
      # Start and enable Docker
      sudo systemctl start docker
      sudo systemctl enable docker
      
      # Add current user to docker group
      sudo usermod -aG docker $USER
      echo -e "${YELLOW}You may need to log out and log back in for docker group membership to take effect${NC}"
    else
      echo -e "${RED}Could not detect Linux distribution${NC}"
      echo -e "${YELLOW}Please install Docker manually${NC}"
      return 1
    fi
    
    echo -e "${GREEN}✓ Docker installed${NC}"
  fi

  # Install Docker Compose if not installed
  if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose already installed${NC}"
  elif docker compose version &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose plugin already installed${NC}"
  else
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
  fi
}

# Function to install NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
  echo -e "${BLUE}Checking for NVIDIA Container Toolkit...${NC}"
  if docker info 2>/dev/null | grep -i nvidia > /dev/null; then
    echo -e "${GREEN}✓ NVIDIA Container Toolkit already installed${NC}"
    return 0
  fi

  echo -e "${YELLOW}Installing NVIDIA Container Toolkit...${NC}"
  
  # Detect distribution
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case $ID in
      ubuntu|debian|linuxmint)
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
          sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
          sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        sudo apt-get update
        sudo apt-get install -y nvidia-container-toolkit
        ;;
      fedora|centos|rhel)
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.repo | \
          sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
        sudo yum install -y nvidia-container-toolkit
        ;;
      *)
        echo -e "${RED}Unsupported distribution: $ID${NC}"
        echo -e "${YELLOW}Please install NVIDIA Container Toolkit manually according to your distribution's documentation${NC}"
        return 1
        ;;
    esac
    
    # Configure Docker runtime
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
    
    echo -e "${GREEN}✓ NVIDIA Container Toolkit installed${NC}"
  else
    echo -e "${RED}Could not detect Linux distribution${NC}"
    echo -e "${YELLOW}Please install NVIDIA Container Toolkit manually${NC}"
    return 1
  fi
}

# Create docker-compose.robust.yml file
create_docker_compose_file() {
  echo -e "${BLUE}Creating docker-compose.robust.yml file...${NC}"
  cat > docker-compose.robust.yml << 'EOL'
version: '3.8'

services:
  comfyui:
    image: wklein92/comfyui:rclone
    container_name: comfyui-instance
    restart: unless-stopped
    ports:
      - "8188:8188"
    volumes:
      - ./models:/opt/comfyui/models  # Persist models
      - ./output:/opt/comfyui/output  # Save outputs
      - ./input:/opt/comfyui/input    # Input files
    environment:
      # Backblaze B2 configuration
      - B2_APPLICATION_KEY_ID=${B2_APPLICATION_KEY_ID:-your_app_key_id}
      - B2_APPLICATION_KEY=${B2_APPLICATION_KEY:-your_app_key}
      - B2_BUCKET_NAME=${B2_BUCKET_NAME:-your_bucket_name}
      
      # Rclone optimization
      - B2_RCLONE_TRANSFERS=${B2_RCLONE_TRANSFERS:-4}
      - B2_RCLONE_CHECKERS=${B2_RCLONE_CHECKERS:-8}
      
      # ComfyUI server settings
      - PORT=8188
      - LISTEN=0.0.0.0
      
      # Performance settings
      - CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-all}  # Control which GPUs to use
      - PYTORCH_CUDA_ALLOC_CONF=${PYTORCH_CUDA_ALLOC_CONF:-max_split_size_mb:512}  # Memory management
      - EXTRA_ARGS=${EXTRA_ARGS:-}  # Any additional args
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              capabilities: [gpu]
              count: ${GPU_COUNT:-all}  # Use all GPUs by default

    # Healthcheck to ensure the service is running properly
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8188"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

# Optional CPU-only fallback profile
# Use with: docker-compose -f docker-compose.robust.yml --profile cpu-only up
  comfyui-cpu:
    profiles: ["cpu-only"]
    image: wklein92/comfyui:rclone
    container_name: comfyui-cpu-instance
    restart: unless-stopped
    ports:
      - "8188:8188"
    volumes:
      - ./models:/opt/comfyui/models
      - ./output:/opt/comfyui/output
      - ./input:/opt/comfyui/input
    environment:
      - B2_APPLICATION_KEY_ID=${B2_APPLICATION_KEY_ID:-your_app_key_id}
      - B2_APPLICATION_KEY=${B2_APPLICATION_KEY:-your_app_key}
      - B2_BUCKET_NAME=${B2_BUCKET_NAME:-your_bucket_name}
      - B2_RCLONE_TRANSFERS=${B2_RCLONE_TRANSFERS:-4}
      - B2_RCLONE_CHECKERS=${B2_RCLONE_CHECKERS:-8}
      - PORT=8188
      - LISTEN=0.0.0.0
      - EXTRA_ARGS="--cpu --disable-cuda-malloc"  # Force CPU mode
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8188"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOL
  echo -e "${GREEN}✓ Created docker-compose.robust.yml${NC}"
}

# Create .env file for configuration
create_env_file() {
  echo -e "${BLUE}Creating .env file...${NC}"
  if [ ! -f .env ]; then
    cat > .env << 'EOL'
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
EOL
    echo -e "${GREEN}✓ Created .env file${NC}"
    echo -e "${YELLOW}Please edit the .env file with your Backblaze B2 credentials${NC}"
  else
    echo -e "${GREEN}✓ .env file already exists${NC}"
  fi
}

# Create start script file
create_start_script() {
  echo -e "${BLUE}Creating start-comfyui.sh script...${NC}"
  cat > start-comfyui.sh << 'EOL'
#!/bin/bash
# Script to start ComfyUI container

# Check GPU availability
GPU_AVAILABLE=false
if command -v nvidia-smi &> /dev/null && docker info 2>/dev/null | grep -i nvidia > /dev/null; then
  echo "✓ GPU support detected"
  
  # Test GPU access in Docker
  echo "Testing GPU access in Docker..."
  if docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo "✓ GPU access in Docker confirmed"
    GPU_AVAILABLE=true
  else
    echo "✗ GPU access in Docker failed"
  fi
else
  echo "✗ GPU support not detected"
fi

# Pull the latest container image
echo "Pulling latest ComfyUI container..."
docker pull wklein92/comfyui:rclone

# Detect Docker Compose command
if command -v docker-compose &> /dev/null; then
  DOCKER_COMPOSE="docker-compose"
else
  DOCKER_COMPOSE="docker compose"
fi

# Start the container
if [ "$GPU_AVAILABLE" = true ]; then
  # Start with GPU support
  echo "Starting ComfyUI with GPU support..."
  $DOCKER_COMPOSE -f docker-compose.robust.yml up -d
else
  # Start in CPU-only mode
  echo "Starting ComfyUI in CPU-only mode (will be slower)..."
  $DOCKER_COMPOSE -f docker-compose.robust.yml --profile cpu-only up -d
fi

echo "ComfyUI is starting!"
echo "Access ComfyUI at http://localhost:8188"
echo "To stop ComfyUI, run: docker-compose -f docker-compose.robust.yml down"
EOL
  chmod +x start-comfyui.sh
  echo -e "${GREEN}✓ Created and made executable start-comfyui.sh${NC}"
}

# Function to test GPU setup
test_gpu_setup() {
  echo -e "${BLUE}Testing GPU setup...${NC}"
  if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA drivers detected${NC}"
    nvidia-smi
  else
    echo -e "${RED}✗ NVIDIA drivers not found${NC}"
    return 1
  fi
  
  if docker info 2>/dev/null | grep -i nvidia > /dev/null; then
    echo -e "${GREEN}✓ NVIDIA Container Toolkit detected${NC}"
  else
    echo -e "${RED}✗ NVIDIA Container Toolkit not found${NC}"
    return 1
  fi
  
  echo -e "${BLUE}Testing GPU access in Docker...${NC}"
  if docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ GPU access in Docker confirmed${NC}"
    return 0
  else
    echo -e "${RED}✗ GPU access in Docker failed${NC}"
    return 1
  fi
}

# Main installation function
main() {
  echo -e "${BLUE}Starting ComfyUI installation...${NC}"
  
  # Check if this is a docker environment (like a container)
  if [ -f /.dockerenv ]; then
    echo -e "${RED}This script should not be run inside a Docker container${NC}"
    exit 1
  fi
  
  # Create installation directory
  INSTALL_DIR="comfyui"
  if [ "$PWD" != *"$INSTALL_DIR"* ]; then
    echo -e "${BLUE}Creating installation directory...${NC}"
    mkdir -p $INSTALL_DIR
    cd $INSTALL_DIR
    echo -e "${GREEN}✓ Changed to directory: $PWD${NC}"
  fi
  
  # Create necessary subdirectories
  mkdir -p models input output
  
  # Install dependencies
  if [ -z "$SKIP_DEPS" ]; then
    # Check if system has nvidia GPU
    if lspci | grep -i nvidia &> /dev/null; then
      install_nvidia_drivers
      install_docker
      install_nvidia_container_toolkit
    else
      echo -e "${YELLOW}No NVIDIA GPU detected. Installing Docker only...${NC}"
      install_docker
    fi
  else
    echo -e "${YELLOW}Skipping dependency installation as requested${NC}"
  fi
  
  # Create configuration files
  create_docker_compose_file
  create_env_file
  create_start_script
  
  # Try to pull the image
  echo -e "${BLUE}Pulling the ComfyUI Docker image...${NC}"
  docker pull wklein92/comfyui:rclone
  
  echo -e "${GREEN}=== Installation Complete ===${NC}"
  echo -e "${YELLOW}You may need to edit the .env file with your Backblaze B2 credentials before starting${NC}"
  echo -e "${BLUE}To start ComfyUI, run: ./start-comfyui.sh${NC}"
  
  # Check if we should start immediately
  if [ "$START_IMMEDIATELY" = "true" ]; then
    echo -e "${BLUE}Starting ComfyUI...${NC}"
    ./start-comfyui.sh
  fi
}

# Process command-line arguments
SKIP_DEPS=false
START_IMMEDIATELY=false

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --skip-deps)
      SKIP_DEPS=true
      shift
      ;;
    --start)
      START_IMMEDIATELY=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $key${NC}"
      echo "Usage: $0 [--skip-deps] [--start]"
      exit 1
      ;;
  esac
done

# Run the main installation
main

exit 0 