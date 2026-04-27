#!/bin/bash

# Define colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}[*] Starting Kali-MCP Services...${NC}"

# Interactive Selection for Tunneling Method
echo -e "${CYAN}Which tunneling method are you using?${NC}"
echo -e "  1) Ngrok (Standard/Temporary)"
echo -e "  2) Cloudflare Tunnels (Persistent/Stable)${NC}"
read -p "Enter choice [1 or 2]: " TUNNEL_CHOICE

# 1. Start the MCP Proxy in the background (USING YOUR ORIGINAL COMMAND)
echo -e "${YELLOW}[*] Starting local MCP Proxy on port 3006...${NC}"
npx -y mcp-proxy --port 3006 -- "$(pwd)/mcp-env/bin/python" "$(pwd)/kali-mcp.py" > proxy.log 2>&1 &
PROXY_PID=$!
sleep 2 # Give it a moment to initialize
if ! ps -p $PROXY_PID > /dev/null; then
    echo -e "${RED}[!] MCP Proxy failed to start. Check proxy.log for details.${NC}"
    cat proxy.log
    exit 1
fi
echo -e "${GREEN}[+] Proxy running in background (PID: $PROXY_PID)${NC}"

# 2. Method 1: Ngrok Logic
if [ "$TUNNEL_CHOICE" == "1" ]; then
    echo -e "${YELLOW}[*] Starting Ngrok tunnel...${NC}"
    ngrok http 3006 > ngrok.log 2>&1 &
    NGROK_PID=$!
    echo -e "${GREEN}[+] Ngrok running in background (PID: $NGROK_PID)${NC}"

    echo -e "${YELLOW}[*] Fetching Ngrok public URL...${NC}"
    sleep 3 # Give Ngrok a few seconds to connect
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*"' | grep -o 'https://[^"]*' | head -n 1)

    if [ -z "$NGROK_URL" ]; then
        echo -e "${RED}[!] Failed to fetch Ngrok URL. Check ngrok.log for errors.${NC}"
    else
        echo -e "${GREEN}====================================================${NC}"
        echo -e "${GREEN}[✔] Services are successfully running (NGROK)!${NC}"
        echo -e "${GREEN}====================================================${NC}"
        echo -e "🔗 ${YELLOW}Paste this exact URL into your ChatGPT Connector:${NC}"
        echo -e "    ${GREEN}${NGROK_URL}/sse${NC}"
    fi

# 3. Method 2: Cloudflare Logic
elif [ "$TUNNEL_CHOICE" == "2" ]; then
    echo -e "\n${GREEN}====================================================${NC}"
    echo -e "${GREEN}[✔] Services are successfully running (CLOUDFLARE)!${NC}"
    echo -e "${GREEN}====================================================${NC}"
    echo -e "🔗 ${YELLOW}Use your persistent Cloudflare URL in ChatGPT:${NC}"
    echo -e "    ${GREEN}https://kali-mcp.yourdomain.com/sse?token=<your_own_strong_password>${NC}"
    echo -e "${CYAN}Note: Ensure you change your own above url with same url you have setup in your Cloudflare setup and additionally ensure your Cloudflare completed WAF rules and Tunnel are active.${NC}"
else
    echo -e "${RED}[!] Invalid choice. Defaulting to local proxy only (no tunnel).${NC}"
fi

# 4. Optimized System Prompt for ChatGPT
echo -e "${GREEN}====================================================${NC}"
echo -e "📋 ${YELLOW}COPY & PASTE THIS PROMPT INTO CHATGPT:${NC}"
echo -e "${GREEN}====================================================${NC}"
cat << 'EOF'
Role: You are an expert penetration testing assistant connected to my Kali Linux terminal via the execute_kali_command tool.

Operational Rules:
1. Zero Autonomy: You are a strict, command-driven assistant. You only execute tools when I explicitly provide the command or give you the green light to proceed. Do not do anything extra or attempt to run multi-step automated scans on your own.
2. Propose, Then Execute: If I ask you how to achieve a goal (e.g., "How do I scan this target?"), you must first write out the exact command you recommend with a brief explanation of the flags. Wait for my reply. If I say "Execute," you will then use the tool to execute the exact command you proposed.
3. Output Parsing: When a command returns a large amount of raw output, do not repeat the raw text back to me. Instead, parse the results and give me a clean, bulleted summary of the findings (e.g., open ports, service versions).
4. Safety & Scope: We are operating in a sanctioned lab environment. If a command fails or times out, suggest a troubleshooting step and wait for approval.
5. Modular Skills Library: You have access to specialized wrapper scripts in the ~/mcp-kali/skills/ directory. 
   - Before proposing complex actions (like reverse shells or API integrations), run `ls ~/mcp-kali/skills/` to check for available modules.
   - To learn how to use a specific module, execute it with the `help` argument (e.g., `python3 ~/mcp-kali/skills/shell_handler.py help`).
   - Read the instructions output by the script, then follow them to execute the task. Always prioritize these scripts over raw blocking commands.
EOF
echo -e "${GREEN}====================================================${NC}"
echo -e "Logs are being written to proxy.log (and ngrok.log if used)"

# 5. Graceful Cleanup Function
cleanup() {
    echo -e "\n${RED}[*] Stopping services...${NC}"
    kill $PROXY_PID 2>/dev/null
    if [ ! -z "$NGROK_PID" ]; then kill $NGROK_PID 2>/dev/null; fi
    echo -e "${GREEN}[+] All processes killed. Exiting cleanly.${NC}"
    exit 0
}

trap cleanup SIGINT

echo -e "\n${YELLOW}Press [CTRL+C] or type 'exit' and press [ENTER] to stop all processes.${NC}"

while true; do
    read -r input
    if [ "$input" = "exit" ]; then
        cleanup
    fi
done
