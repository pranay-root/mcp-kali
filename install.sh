#!/bin/bash

# Define colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}[*] Starting Kali-MCP Dependencies Installation...${NC}"

# Ask user for their preferred tunneling method
echo -e "${CYAN}Which tunneling method will you use?${NC}"
echo -e "  1) Ngrok (Quick setup, temporary URLs, free tier timeouts)"
echo -e "  2) Cloudflare Tunnels (Persistent URL, requires custom domain)"
read -p "Enter choice [1 or 2]: " TUNNEL_CHOICE

# 1. System Updates and Base Dependencies
echo -e "\n${YELLOW}[*] Step 1: Installing system dependencies (Python venv, curl)...${NC}"
sudo apt update
sudo apt install -y python3-venv python3-pip curl
sudo apt install -y npm

# 2. Python Virtual Environment & SDK
echo -e "${YELLOW}[*] Step 2: Setting up isolated Python virtual environment...${NC}"
if [ ! -d "mcp-env" ]; then
    python3 -m venv mcp-env
    echo -e "${GREEN}[+] Virtual environment 'mcp-env' created.${NC}"
else
    echo -e "${YELLOW}[!] 'mcp-env' already exists. Skipping creation.${NC}"
fi

echo -e "${YELLOW}[*] Installing Python MCP SDK into the virtual environment...${NC}"
./mcp-env/bin/pip install mcp uvicorn starlette

# 3. Tunnel Installation based on user choice
if [ "$TUNNEL_CHOICE" == "1" ]; then
    echo -e "${YELLOW}[*] Step 3: Adding official Ngrok repository and installing...${NC}"
    if ! command -v ngrok &> /dev/null; then
        curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/keyrings/ngrok.asc >/dev/null
        echo "deb [signed-by=/etc/apt/keyrings/ngrok.asc] https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
        sudo apt update && sudo apt install -y ngrok
        echo -e "${GREEN}[+] Ngrok installed successfully.${NC}"
    else
        echo -e "${GREEN}[+] Ngrok is already installed. Skipping.${NC}"
    fi
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}[✔] Installation Complete!${NC}"
    echo -e "Before running the tool, ensure you authenticate Ngrok:"
    echo -e "  ${YELLOW}ngrok config add-authtoken <YOUR_TOKEN>${NC}"
    echo -e "${GREEN}====================================================${NC}"

elif [ "$TUNNEL_CHOICE" == "2" ]; then
    echo -e "${YELLOW}[*] Step 3: Installing Cloudflare 'cloudflared' daemon...${NC}"
    if ! command -v cloudflared &> /dev/null; then
        curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
        sudo dpkg -i cloudflared.deb
        rm cloudflared.deb
        echo -e "${GREEN}[+] Cloudflared installed successfully.${NC}"
    else
        echo -e "${GREEN}[+] Cloudflared is already installed. Skipping.${NC}"
    fi
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}[✔] Installation Complete!${NC}"
    echo -e "${YELLOW}[!] IMPORTANT FOR CLOUDFLARE SETUP:${NC}"
    echo -e "Please check the README.md for instructions on configuring your"
    echo -e "Cloudflare Zero Trust dashboard and creating the WAF security rule."
    echo -e "${GREEN}====================================================${NC}"
else
    echo -e "${RED}[!] Invalid choice. Please run the script again.${NC}"
    exit 1
fi
