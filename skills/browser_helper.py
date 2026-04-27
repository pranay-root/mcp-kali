import sys
import requests
from bs4 import BeautifulSoup
import urllib3

# Suppress insecure request warnings (common in pentest labs with self-signed certs)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Set a standard User-Agent so targets don't block us as a generic python script
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

MAX_OUTPUT = 8000  # Truncate large pages to save AI context

def print_instructions():
    print("""
[SKILL INSTRUCTIONS: BROWSER HELPER]
Description: A stateless, text-based web browser for inspecting web targets.
Rules: Use this to read web pages, find hidden links, or inspect headers instead of raw curl commands.

Usage:
  python3 browser_helper.py text <url>    -> Returns only the readable human text of the page
  python3 browser_helper.py html <url>    -> Returns the raw HTML source code
  python3 browser_helper.py headers <url> -> Returns the HTTP response headers
  python3 browser_helper.py links <url>   -> Extracts and lists all href links found on the page
""")

def fetch_page(url):
    if not url.startswith("http"):
        url = "http://" + url
    try:
        response = requests.get(url, headers=HEADERS, verify=False, timeout=10)
        return response
    except requests.exceptions.RequestException as e:
        print(f"[!] Error fetching {url}: {str(e)}")
        sys.exit(1)

def main():
    if len(sys.argv) < 3 or sys.argv[1].lower() == "help":
        print_instructions()
        return

    action = sys.argv[1].lower()
    url = sys.argv[2]
    
    response = fetch_page(url)
    soup = BeautifulSoup(response.text, 'html.parser')

    output = ""

    if action == "text":
        # Extract text and remove excess whitespace
        output = soup.get_text(separator='\n', strip=True)
        print(f"[*] Readable Text from {url}:\n")

    elif action == "html":
        output = response.text
        print(f"[*] Raw HTML from {url}:\n")

    elif action == "headers":
        print(f"[*] HTTP Headers from {url}:\n")
        for key, value in response.headers.items():
            output += f"{key}: {value}\n"

    elif action == "links":
        print(f"[*] Links found on {url}:\n")
        links = []
        for a in soup.find_all('a', href=True):
            links.append(a['href'])
        # Remove duplicates while preserving order
        unique_links = list(dict.fromkeys(links))
        output = "\n".join(unique_links)
        if not output:
            output = "No links found."

    else:
        print("[!] Unknown action. Run with 'help' for usage.")
        return

    # Truncation to protect AI context window
    if len(output) > MAX_OUTPUT:
        print(output[:MAX_OUTPUT])
        print(f"\n...[TRUNCATED: Showing first {MAX_OUTPUT} characters to prevent context overflow]...")
    else:
        print(output)

if __name__ == "__main__":
    main()
