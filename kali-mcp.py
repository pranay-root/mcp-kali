from mcp.server.fastmcp import FastMCP
import subprocess

mcp = FastMCP("Kali Command Interface")

@mcp.tool()
def execute_kali_command(command: str) -> str:
    """
    Executes a provided shell command on the Kali host.
    Strictly runs the provided input. Long outputs are safely truncated.
    """
    MAX_OUTPUT_LENGTH = 16000 # Keeps output well within LLM context limits

    try:
        # Run command with a 2-minute timeout for heavier scans
        result = subprocess.run(
            command, 
            shell=True, 
            capture_output=True, 
            text=True, 
            timeout=180
        )
        
        output = result.stdout if result.returncode == 0 else result.stderr
        
        if not output:
            return "Command executed successfully (no output)."
            
        # Truncate massive outputs to prevent connection crashing
        if len(output) > MAX_OUTPUT_LENGTH:
            truncated_msg = f"\n...[OUTPUT TRUNCATED: Showing first {MAX_OUTPUT_LENGTH} chars]..."
            return output[:MAX_OUTPUT_LENGTH] + truncated_msg
            
        return output
            
    except subprocess.TimeoutExpired:
        return "Error: Command timed out after 120 seconds. If running a long scan, output it to a file instead."
    except Exception as e:
        return f"Execution Exception: {str(e)}"

if __name__ == "__main__":
    mcp.run()
