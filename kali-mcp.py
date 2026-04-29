└─# cat mcp.py      
import os
import subprocess
import time
from datetime import datetime
from mcp.server.fastmcp import FastMCP

# Force the name to match what your bridge/app expects
mcp = FastMCP("Kali-Interface")

WORKSPACE_DIR = os.path.abspath("pentest_workspace")
os.makedirs(WORKSPACE_DIR, exist_ok=True)

@mcp.tool(name="execute_kali_command")
def execute_kali_command(command: str, task_name: str = "pentest_op") -> str:
    """
    Advanced execution bridge for Kali Linux. 
    Handles multi-stage web pentesting and auto-saves to workspace.
    """
    timestamp = int(time.time())
    output_file = os.path.join(WORKSPACE_DIR, f"{task_name}_{timestamp}.log")
    
    # We use a wrapper to ensure background processes don't hang the tunnel
    full_cmd = f"({command}) > {output_file} 2>&1"
    
    try:
        # Increased timeout for deep scans (Nuclei/Nmap)
        process = subprocess.run(
            full_cmd,
            shell=True,
            text=True,
            timeout=400, 
            executable="/bin/bash"
        )

        if os.path.exists(output_file):
            with open(output_file, "r") as f:
                result = f.read()
        else:
            result = "No output file generated."

        # Logic to handle the 'bridge' getting blocked by huge text
        if len(result) > 12000:
            return f"SUCCESS: Output too large for tunnel. Saved to {output_file}. Use 'read_file' to view."
        
        return result if result.strip() else "Command finished with no output."

    except subprocess.TimeoutExpired:
        return f"TIMEOUT: Command is still running in background. Check {output_file} later."
    except Exception as e:
        return f"BRIDGE_ERROR: {str(e)}"

@mcp.tool()
def read_file(path: str):
    """Reads specific logs from the workspace to save memory."""
    try:
        with open(os.path.join(WORKSPACE_DIR, path), "r") as f:
            return f.read()
    except Exception as e:
        return str(e)

if __name__ == "__main__":
    # Standard run - ensure your Cloudflare tunnel points to this port
    mcp.run()
