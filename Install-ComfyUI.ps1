# ComfyUI All-in-One Installer Script for Windows
# PowerShell script to set up ComfyUI with GPU support

# Function to show colored output
function Write-Color {
    param (
        [Parameter(Position=0)]
        [string]$Text,
        [Parameter(Position=1)]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Text -ForegroundColor $ForegroundColor
}

# Print banner
Write-Color "  ______              __      _   _ ___    _____           __        ____         " "Cyan"
Write-Color " / ____/___  ____ _/ _|_   _| | | |_ _|  |_   _|__  ___ / _|____  / / /__  _____" "Cyan"
Write-Color "| |   / __ \/ __ \| |_| | | | | | || |     | |/ _ \/ __| |_|_  / / / / _ \/ ___/" "Cyan"
Write-Color "| |__| (_) | | | |  _| |_| | |_| || |     | |  __/\__ \  _|/ /_/ / /  __/ /    " "Cyan"
Write-Color " \____\____/|_| |_|_|  \__, |\___/|___|    |_|\___||___/_|/___/_/_/\___/_/     " "Cyan"
Write-Color "                       |___/                                                     " "Cyan"
Write-Color "Windows Installer" "Cyan"
Write-Color ""

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Color "This script requires administrator privileges. Please run as administrator." "Red"
    exit 1
}

# Function to check for NVIDIA drivers
function Test-NvidiaDrivers {
    Write-Color "Checking for NVIDIA drivers..." "Blue"
    try {
        $null = & nvidia-smi
        Write-Color "✓ NVIDIA drivers detected" "Green"
        return $true
    } catch {
        Write-Color "✗ NVIDIA drivers not found" "Red"
        Write-Color "Please download and install NVIDIA drivers from https://www.nvidia.com/Download/index.aspx" "Yellow"
        return $false
    }
}

# Function to check for Docker Desktop
function Test-DockerDesktop {
    Write-Color "Checking for Docker Desktop..." "Blue"
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-Color "✓ Docker Desktop is installed" "Green"
        return $true
    } else {
        Write-Color "✗ Docker Desktop is not installed" "Red"
        Write-Color "Please download and install Docker Desktop from https://www.docker.com/products/docker-desktop/" "Yellow"
        Write-Color "Make sure to enable WSL 2 integration and NVIDIA GPU support in Docker Desktop settings" "Yellow"
        return $false
    }
}

# Function to check Docker GPU support
function Test-DockerGPU {
    Write-Color "Testing GPU support in Docker..." "Blue"
    try {
        $output = docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Color "✓ GPU access in Docker confirmed" "Green"
            return $true
        } else {
            Write-Color "✗ GPU access in Docker failed" "Red"
            Write-Color "Please enable GPU support in Docker Desktop:" "Yellow"
            Write-Color "  1. Open Docker Desktop" "Yellow"
            Write-Color "  2. Go to Settings > Resources > WSL Integration" "Yellow"
            Write-Color "  3. Check 'Enable NVIDIA GPU support for WSL 2'" "Yellow"
            Write-Color "  4. Click Apply & Restart" "Yellow"
            return $false
        }
    } catch {
        Write-Color "✗ GPU access in Docker failed: $_" "Red"
        return $false
    }
}

# Create necessary files
function Create-ConfigFiles {
    param (
        [string]$InstallDir
    )
    
    # Create docker-compose.robust.yml
    Write-Color "Creating docker-compose.robust.yml file..." "Blue"
    $dockerComposeContent = @'
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
'@
    $dockerComposeContent | Out-File -FilePath "$InstallDir\docker-compose.robust.yml" -Encoding utf8
    Write-Color "✓ Created docker-compose.robust.yml" "Green"
    
    # Create .env file if it doesn't exist
    if (-not (Test-Path "$InstallDir\.env")) {
        Write-Color "Creating .env file..." "Blue"
        $envContent = @'
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
'@
        $envContent | Out-File -FilePath "$InstallDir\.env" -Encoding utf8
        Write-Color "✓ Created .env file" "Green"
        Write-Color "Please edit the .env file with your Backblaze B2 credentials" "Yellow"
    } else {
        Write-Color "✓ .env file already exists" "Green"
    }
    
    # Create Start-ComfyUI.ps1 script
    Write-Color "Creating Start-ComfyUI.ps1 script..." "Blue"
    $startScript = @'
# PowerShell script to start ComfyUI with GPU detection

# Function to check for NVIDIA drivers
function Test-NvidiaDrivers {
    try {
        $null = & nvidia-smi
        Write-Host "✓ NVIDIA drivers detected" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ NVIDIA drivers not found" -ForegroundColor Red
        return $false
    }
}

# Function to check Docker GPU support
function Test-DockerGPU {
    Write-Host "Testing GPU support in Docker..." -ForegroundColor Blue
    try {
        $output = docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ GPU access in Docker confirmed" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ GPU access in Docker failed" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ GPU access in Docker failed: $_" -ForegroundColor Red
        return $false
    }
}

# Check Docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check GPU availability
$gpuAvailable = (Test-NvidiaDrivers) -and (Test-DockerGPU)

# Pull the latest container image
Write-Host "Pulling latest ComfyUI container..." -ForegroundColor Blue
docker pull wklein92/comfyui:rclone

# Start the container
if ($gpuAvailable) {
    Write-Host "=== GPU setup complete, starting ComfyUI with GPU support ===" -ForegroundColor Green
    docker-compose -f docker-compose.robust.yml up -d
} else {
    Write-Host "=== GPU not available, starting ComfyUI in CPU-only mode ===" -ForegroundColor Yellow
    Write-Host "Note: ComfyUI will be much slower without GPU acceleration" -ForegroundColor Yellow
    docker-compose -f docker-compose.robust.yml --profile cpu-only up -d
}

# Display access information
Write-Host "=== ComfyUI is starting! ===" -ForegroundColor Green
Write-Host "Access ComfyUI at http://localhost:8188" -ForegroundColor Blue
Write-Host "To stop ComfyUI, run: docker-compose -f docker-compose.robust.yml down" -ForegroundColor Yellow

# Check container status
Write-Host "Checking container status..." -ForegroundColor Blue
Start-Sleep -Seconds 5
docker-compose -f docker-compose.robust.yml ps
'@
    $startScript | Out-File -FilePath "$InstallDir\Start-ComfyUI.ps1" -Encoding utf8
    Write-Color "✓ Created Start-ComfyUI.ps1" "Green"
    
    # Create desktop shortcut
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\ComfyUI.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$InstallDir\Start-ComfyUI.ps1`""
    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.Description = "Start ComfyUI"
    $Shortcut.IconLocation = "shell32.dll,4"
    $Shortcut.Save()
    Write-Color "✓ Created desktop shortcut" "Green"
}

# Main installation function
function Install-ComfyUI {
    param (
        [switch]$SkipChecks,
        [switch]$StartImmediately
    )
    
    Write-Color "Starting ComfyUI installation..." "Blue"
    
    # Create installation directory
    $installDir = Join-Path $env:USERPROFILE "ComfyUI"
    if (-not (Test-Path $installDir)) {
        Write-Color "Creating installation directory at $installDir..." "Blue"
        New-Item -Path $installDir -ItemType Directory | Out-Null
    }
    
    # Change to the installation directory
    Set-Location $installDir
    Write-Color "✓ Using directory: $installDir" "Green"
    
    # Create necessary subdirectories
    New-Item -Path (Join-Path $installDir "models") -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path $installDir "input") -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path $installDir "output") -ItemType Directory -Force | Out-Null
    
    # Check for dependencies
    if (-not $SkipChecks) {
        $nvidiaOk = Test-NvidiaDrivers
        $dockerOk = Test-DockerDesktop
        
        if ($nvidiaOk -and $dockerOk) {
            $gpuOk = Test-DockerGPU
        }
        
        if (-not ($dockerOk)) {
            Write-Color "Docker Desktop is required. Please install it and run this script again." "Red"
            Write-Color "Download Docker Desktop from: https://www.docker.com/products/docker-desktop/" "Yellow"
            return
        }
    } else {
        Write-Color "Skipping dependency checks as requested" "Yellow"
    }
    
    # Create config files
    Create-ConfigFiles -InstallDir $installDir
    
    # Pull the Docker image
    Write-Color "Pulling the ComfyUI Docker image..." "Blue"
    docker pull wklein92/comfyui:rclone
    
    Write-Color "=== Installation Complete ===" "Green"
    Write-Color "You may need to edit the .env file with your Backblaze B2 credentials before starting" "Yellow"
    Write-Color "To start ComfyUI, run Start-ComfyUI.ps1 or use the desktop shortcut" "Blue"
    
    # Start ComfyUI if requested
    if ($StartImmediately) {
        Write-Color "Starting ComfyUI..." "Blue"
        & "$installDir\Start-ComfyUI.ps1"
    }
}

# Process command-line parameters
param (
    [switch]$SkipChecks,
    [switch]$StartImmediately
)

# Run the installation
Install-ComfyUI -SkipChecks:$SkipChecks -StartImmediately:$StartImmediately 