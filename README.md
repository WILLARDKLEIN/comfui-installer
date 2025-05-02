# Moby Dick Summarizer

This Python script uses the DeepSeek AI API to create chapter summaries of Herman Melville's "Moby Dick" in the first-person voice of Ishmael (the narrator). The summaries are saved in a structured JSON format.

## Sample Output

The script produces a JSON file with an array of chapter objects, each containing:
- `number`: Chapter number
- `title`: Chapter title
- `summary`: AI-generated summary in first-person voice

See `sample_output.json` for examples of the format and style.

## Requirements

- Python 3.6+
- DeepSeek API key
- Required packages: requests, beautifulsoup4

## Installation

1. Clone this repository
2. Install required dependencies:
```
pip install -r requirements.txt
```

## Configuration

Before running the script, you need to set up your DeepSeek API key:

1. Open `moby_dick_summarizer.py`
2. Replace `YOUR_DEEPSEEK_API_KEY` with your actual DeepSeek API key:
```python
API_KEY = "YOUR_DEEPSEEK_API_KEY"  # Replace with your actual API key
```

## Usage

Run the script:

```
python moby_dick_summarizer.py
```

The script will:
1. Fetch the full text of Moby Dick from Project Gutenberg
2. Extract all chapters
3. Generate a summary for each chapter using the DeepSeek API
4. Save all summaries to `moby_dick_summaries.json`

## Notes

- The script includes a small delay between API calls to respect rate limits
- The summaries are generated in first-person voice to match the style of the original
- Each summary is approximately 100-150 words

## Customization

You can modify the prompt in the `summarize_chapter_with_deepseek()` function to change the style, length, or focus of the summaries. 

# ComfyUI with Robust GPU Support and B2 Integration

This repository provides a robust Docker setup for ComfyUI with Backblaze B2 integration and intelligent GPU detection.

## Features

- **Reliable Model Management**: Uses rclone for efficient and reliable file transfers from Backblaze B2
- **Smart GPU Detection**: Automatically detects NVIDIA GPU availability
- **CPU Fallback**: Gracefully falls back to CPU mode when GPUs aren't available
- **Cross-Platform**: Works on Windows, Linux, and macOS
- **Optimized Performance**: Configurable settings for best performance
- **One-Command Setup**: Install everything with a single command

## Quick Start

### Linux/Mac One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/comfyui-install/main/install-comfyui.sh | bash
```

### Windows One-Line Install

Run this in PowerShell as Administrator:

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/yourusername/comfyui-install/main/install-comfyui.ps1'))
```

That's it! The installer will automatically:

1. Check for NVIDIA GPU
2. Install required dependencies
3. Set up Docker and NVIDIA Container Toolkit if needed
4. Create configuration files
5. Pull the Docker image
6. Create startup scripts

## Manual Installation

If you prefer a manual approach:

### Linux/Mac

1. Download the installer:
   ```bash
   wget https://raw.githubusercontent.com/yourusername/comfyui-install/main/comfyui-installer.sh
   chmod +x comfyui-installer.sh
   ```

2. Run the installer:
   ```bash
   ./comfyui-installer.sh
   ```

   Options:
   - `--skip-deps`: Skip dependency installation
   - `--start`: Start ComfyUI immediately after installation

### Windows

1. Download the installer:
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/comfyui-install/main/Install-ComfyUI.ps1" -OutFile "Install-ComfyUI.ps1"
   ```

2. Run the installer as Administrator:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "Install-ComfyUI.ps1"
   ```

   Parameters:
   - `-SkipChecks`: Skip dependency checks
   - `-StartImmediately`: Start ComfyUI after installation

## Configuration

After installation, you'll find the following files in your ComfyUI directory:

- `.env`: Configure your Backblaze B2 credentials and performance settings
- `docker-compose.robust.yml`: Docker Compose configuration
- `start-comfyui.sh` or `Start-ComfyUI.ps1`: Script to start ComfyUI

### Backblaze B2 Configuration

Edit the `.env` file to add your Backblaze B2 credentials:

```
B2_APPLICATION_KEY_ID=your_app_key_id
B2_APPLICATION_KEY=your_app_key
B2_BUCKET_NAME=your_bucket_name
```

## Using ComfyUI

After installation:

1. On Linux/Mac: Run `./start-comfyui.sh`
2. On Windows: Run `Start-ComfyUI.ps1` or use the desktop shortcut

Access ComfyUI in your browser at: http://localhost:8188

## Troubleshooting

### GPU Issues

If you're having trouble with GPU detection:

1. Ensure NVIDIA drivers are installed and up-to-date
2. Check Docker Desktop settings (on Windows) to ensure GPU support is enabled
3. Run the script with administrator/root privileges
4. Check nvidia-smi output to ensure your GPU is recognized

### Docker Issues

- Ensure Docker is running
- On Windows, make sure WSL 2 is properly configured
- Check Docker logs: `docker logs comfyui-instance`

## License

This project is licensed under the MIT License - see the LICENSE file for details. 