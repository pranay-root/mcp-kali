# ⚡Kali-MCP: Command-Driven AI Pentesting Interface

[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![MCP](https://img.shields.io/badge/Model_Context_Protocol-Latest-purple.svg)](https://modelcontextprotocol.io/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-Zero_Trust-orange.svg)](https://one.dash.cloudflare.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Kali-MCP is a secure, zero-autonomy Model Context Protocol (MCP) server that bridges web-based Large Language Models (LLMs) directly to a local Kali Linux terminal. It allows you to use an AI as a command-driven assistant for penetration testing tasks, with flexible and secure tunneling options through Ngrok or Cloudflare Zero Trust.

## Features
*   **Zero-Autonomy Execution:** The AI operates strictly as a command interface under human oversight. It proposes commands, and you approve their execution.
*   **Dual-Tunneling Architecture:** Supports both quick, temporary tunneling with Ngrok and a persistent, stable setup using Cloudflare Tunnels.
*   **Output Optimization:** Automatically truncates massive terminal outputs to preserve LLM context and prevent connection issues.
*   **WAF-Hardened Security:** Built-in support for Cloudflare's Web Application Firewall to protect your public-facing terminal from unauthorized access.
*   **Modular Skills:** Includes a `skills` directory with helper scripts (e.g., `browser_helper.py`) to perform complex tasks more efficiently than raw shell commands.

## Prerequisites
*   **OS:** Kali Linux
*   **Python:** Version 3.8+ with `venv`
*   **Domain (Cloudflare Method):** A custom domain with its nameservers pointed to Cloudflare.

## Installation
1.  Clone the repository and navigate into the directory:
    ```bash
    git clone https://github.com/pranay-root/mcp-kali.git
    cd mcp-kali
    ```

2.  Make the scripts executable and run the installer:
    ```bash
    chmod +x install.sh start.sh
    ./install.sh
    ```
    The installer will prompt you to choose your preferred tunneling method (Ngrok or Cloudflare), which installs the necessary dependencies.

## Method 1: Quick Start (Ngrok)
This method is ideal for quick tests and temporary sessions.

1.  **Authenticate Ngrok:** If you haven't already, add your Ngrok authtoken. You can find this on your [Ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken).
    ```bash
    ngrok config add-authtoken YOUR_NGROK_TOKEN
    ```

2.  **Start the Service:** Run the start script and choose the Ngrok option.
    ```bash
    ./start.sh
    ```
    Select **Option 1** when prompted. The script will start the MCP server and the Ngrok tunnel, then display the public URL.

3.  **Connect to ChatGPT:** Copy the generated URL (e.g., `https://your-id.ngrok-free.app/sse`) and proceed to the [ChatGPT Integration](#-chatgpt-integration) section.

## Method 2: Persistent Setup (Cloudflare)
This method provides a stable, persistent URL and is recommended for regular use.

#### Step 1: Authenticate Cloudflare on Kali
Link your Kali machine to your Cloudflare account by running:
```bash
cloudflared tunnel login
```
Follow the URL provided in the terminal to log in and authorize your domain.

#### Step 2: Create and Configure the Cloudflare Tunnel
1.  Navigate to the [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/) and go to **Networks -> Tunnels**.
2.  Click **Create a tunnel**, select `Cloudflared` as the connector type, and give it a name (e.g., `kali-mcp`). Save the tunnel.
3.  On the Tunnels list, click the three dots next to your `kali-mcp` tunnel, and select **Configure**.
3.  On the next page, click on add connector choose your OS (Debian) and copy the command provided in the box. 
4.  It will look like this `sudo cloudflared service install eyJhIjoiMzEyMDliND***********************************************` 
5.  Go to the **Published application routes** tab and click **Add a Published application routes**.
6.  Configure the route:
    *   **Subdomain:** `kali-mcp` (or your preferred name)
    *   **Domain:** Select your custom domain.
    *   **Service -> Type:** `HTTP`
    *   **Service -> URL:** `localhost:3006`
7.  Click **Save hostname**.

#### Step 3: Secure the Tunnel with a WAF Rule
This is a **critical step** to prevent unauthorized access to your terminal.

1.  Navigate to your main **Domain Dashboard** (not the Zero Trust dashboard).
2.  Go to **Security -> Security Rules**.
3.  Click **Create rule -> Custom rules**.
4.  Configure the rule:
    *   **Rule name:** `Protect Kali MCP`
    *   **Field:** `URI Query String`
    *   **Operator:** `does not contain`
    *   **Value:** `token=<your_own_strong_password>`
    *   Click **And**.
    *   **Field:** `Request Method`
    *   **Operator:** `does not equal`
    *   **Value:** `OPTIONS`
    *   **Action:** `Block`
5.  Click **Deploy**.

#### Step 4: Start the Service
Run the start script and choose the Cloudflare option.
```bash
./start.sh
```
Select **Option 2** when prompted. The script will start the local MCP server.

## ChatGPT Integration

1.  In ChatGPT, go to **Settings -> Connectors -> Developer Mode -> New App**.
2.  **Authentication:** Select `No Auth`.
3.  **MCP Server URL:** Paste your URL, formatted as follows:
    *   **Ngrok:** `https://your-id.ngrok-free.app/sse`
    *   **Cloudflare:** `https://kali-mcp.yourdomain.com/sse?token=<your_own_strong_password>`
4.  Click **Create** and enable the connector.

### Recommended System Prompt
For best results, use the following system prompt in ChatGPT to guide the AI's behavior. The `start.sh` script will also print this for you to copy.

```
Role: You are an expert penetration testing assistant connected to my Kali Linux terminal via the execute_kali_command tool.

Operational Rules:
1. Zero Autonomy: You are a strict, command-driven assistant. You only execute tools when I explicitly provide the command or give you the green light to proceed. Do not do anything extra or attempt to run multi-step automated scans on your own.
2. Propose, Then Execute: If I ask you how to achieve a goal (e.g., "How do I scan this target?"), you must first write out the exact command you recommend with a brief explanation of the flags. Wait for my reply. If I say "Execute," you will then use the tool to execute the exact command you proposed.
3. Output Parsing: When a command returns a large amount of raw output, do not repeat the raw text back to me. Instead, parse the results and give me a clean, bulleted summary of the findings (e.g., open ports, service versions).
4. Safety & Scope: We are operating in a sanctioned lab environment. If a command fails or times out, suggest a troubleshooting step and wait for approval.
5. Modular Skills Library: You have access to specialized wrapper scripts in the ~/mcp-kali/skills/ directory. 
   - Before proposing complex actions (like reverse shells or API integrations), run `ls ~/mcp-kali/skills/` to check for available modules.
   - To learn how to use a specific module, execute it with the `help` argument (e.g., `python3 ~/mcp-kali/skills/browser_helper.py help`).
   - Read the instructions output by the script, then follow them to execute the task. Always prioritize these scripts over raw blocking commands.
```

## 🚧 Project Status

[![Status](https://img.shields.io/badge/Status-Under_Development-red.svg)]()
[![Contributions](https://img.shields.io/badge/Contributions-Welcome-brightgreen.svg)]()
[![Focus](https://img.shields.io/badge/Focus-Skills_Page-blue.svg)]()
[![Feedback](https://img.shields.io/badge/Feedback-Open-orange.svg)]()

This project is currently under active development. Features and content—especially the **Skills page**—are still being built and refined.


### 🤝 Contributing

We welcome contributions from the community!
If you’d like to improve the **skills section** or add new features, feel free to open a pull request.

### 💡 Suggestions & Improvements

Have ideas or feedback?
Open an issue and let us know—we’re always looking to improve.



