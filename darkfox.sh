#!/usr/bin/env bash

#######################################################
# Made for CTI OSINT cyber security research on the Dark Deep Web
# Intended to be used on Kali Linux
# Updated for compatibility and better Tor handling
# Hacked on 07/01/2026, pay me later
# Great ideas
# Maybe run darkfox two times to make sure everything is installed.
# Go here --> https://addons.mozilla.org/en-US/firefox/addon/noscript/
# install_addon "https://addons.mozilla.org/firefox/downloads/file/4141345/noscript-11.4.26.xpi" "noscript"
# install_addon "https://addons.mozilla.org/firefox/downloads/file/4125998/adblock_plus-3.17.1.xpi" "adblock_plus"
# install_addon "https://addons.mozilla.org/firefox/downloads/file/4151024/sponsorblock-5.4.15.xpi" "sponsorblock"
# install_addon "https://addons.mozilla.org/firefox/downloads/file/4329214/easy_auto_refresh-5.6.xpi" "easy auto refresh"
# Good to know: https://github.com/aryanguenthner/deepdarkCTI/blob/main/ransomware_gang.md

######################################################

# Banner
cat <<'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ██████╗  █████╗ ██████╗ ██╗  ██╗███████╗ ██████╗ ██╗  ██╗  ║
║   ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝██╔════╝██╔═══██╗╚██╗██╔╝  ║
║   ██║  ██║███████║██████╔╝█████╔╝ █████╗  ██║   ██║ ╚███╔╝   ║
║   ██║  ██║██╔══██║██╔══██╗██╔═██╗ ██╔══╝  ██║   ██║ ██╔██╗   ║
║   ██████╔╝██║  ██║██║  ██║██║  ██╗██║     ╚██████╔╝██╔╝ ██╗  ║
║   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝  ║
║                                                              ║
║            CTI Cyber Threat Intelligence Tool                ║
║                  Dark Web OSINT Research                     ║
║                        Version 3.0                           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo "OSINT CTI Cyber Threat intelligence v1.2"

echo
# Todays Date
sudo timedatectl set-timezone America/Los_Angeles
echo -e "\e[034mDate:\e[0m"
date '+%Y-%m-%d %r' | tee darkfox.run.date
# Setting Variables
CITY=$(curl -s http://ip-api.com/line?fields=timezone | cut -d "/" -f 2)
PWD=$(pwd)
GREEN=032m
YELLOW=033m
RED=031m
RED='\033[31m'
BLUE=034m
echo

# Consistent status message helpers
print_skip() {
    echo -e "\e[33m[SKIP]\e[0m $1"
}
print_found() {
    echo -e "\e[32m[OK]\e[0m Found $1"
}

# Keep the screen on during investigations
xset s off            # Disable screensaver
xset s noblank        # No screen blanking
xset -dpms            # Disable DPMS power saving

# Dependencies Check
echo "Checking Requirements, Chill for a sec"
echo
sudo apt-get update > /dev/null 2>&1
LOGFILE="/var/log/kali_apt_install_errors.log"
PACKAGES=( jq tor torbrowser-launcher python3-stem libreoffice )

echo "Starting package installs..."
echo
echo "Errors will be logged to: $LOGFILE"
echo
echo "" > "$LOGFILE"

for pkg in "${PACKAGES[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        print_skip "$pkg is already installed."
    else
        echo -e "\e[32m[INSTALLING]\e[0m $pkg..."
        if ! apt-get -y install "$pkg"; then
            echo "[ERROR] Failed to install: $pkg" | tee -a "$LOGFILE"
            echo -e "\e[31m[FAILED]\e[0m Could not install $pkg"
        fi
    fi
done

# Add Desktop Launcher
LAUNCHER_SOURCE="/opt/darkfox/DarkFox.desktop"
LAUNCHER_DEST="/home/kali/Desktop/DarkFox.desktop"

if [ -f "$LAUNCHER_DEST" ]; then
    print_skip "DarkFox launcher already exists on Desktop."
else
    echo "Adding DarkFox launcher to Desktop..."
    cp "$LAUNCHER_SOURCE" "$LAUNCHER_DEST"
    chmod 777 "$LAUNCHER_DEST"
fi 
echo

# Network Information
echo -e "\e[031mCurrent Network Information\e[0m"
EXT=$(curl -s https://api64.ipify.org || curl -s https://ifconfig.me || curl -s https://checkip.amazonaws.com)

if [[ -z "$EXT" ]]; then
    EXT="Unavailable"
fi

LOCATION=$(curl -s ipinfo.io/json)
COUNTRY=$(echo "$LOCATION" | jq -r '.country')
REGION=$(echo "$LOCATION" | jq -r '.region')
CITY=$(echo "$LOCATION" | jq -r '.city')
KALI=$(hostname -I | awk '{print $1}')

echo "---------------------------------"
printf "| %-12s | %-20s |\n" "Label" "Value"
echo "---------------------------------"
printf "| %-12s | %-20s |\n" "Public IP" "$EXT"
printf "| %-12s | %-20s |\n" "Country" "$COUNTRY"
printf "| %-12s | %-20s |\n" "State" "$REGION"
printf "| %-12s | %-20s |\n" "City" "$CITY"
printf "| %-12s | %-20s |\n" "Kali IP" "$KALI"
echo "---------------------------------"
echo

echo -ne '#####                     (33%)\r'
sleep 1
echo -ne '#############             (66%)\r'
sleep 1
echo -ne '#######################   (100%)\r'
echo -ne '\n'
echo

# Create OSINT investigations folder
mkdir -p "$(pwd)/investigations"

# Verify LibreOffice is installed
L="/usr/bin/libreoffice"
if [ -f "$L" ]; then
    print_found "LibreOffice"
else
    echo -e "\e[031mPlease wait while LibreOffice is installed\e[0m"
    sudo apt-get install -y libreoffice
fi
echo

cd /home/kali/Downloads || exit 1

# Google Chrome Installer
GC="/usr/bin/google-chrome-stable"
if [ -f "$GC" ]; then
    print_found "Google Chrome"
else
    echo "Google Chrome not found. Installing..."
    CHROME_DEB_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    DEB_FILE="google-chrome-stable_current_amd64.deb"
    wget -O "$DEB_FILE" "$CHROME_DEB_URL"
    sudo dpkg -i "$DEB_FILE"
    sudo apt-get install -f -y
    rm "$DEB_FILE"
    echo "Google Chrome installation complete!"
    echo
fi
echo

mkdir -p /opt/darkfox
DARKFOX_DIR="/opt/darkfox"
cd "$DARKFOX_DIR" || exit 1

# Verify gowitness
GOWIT="/opt/darkfox/gowitness"
if [ -f "$GOWIT" ]; then
    print_found "GoWitness 3.0.5"
else
    echo -e "\e[031mDownloading Missing GoWitness 3.0.5\e[0m"
    wget --no-check-certificate -O gowitness 'https://drive.google.com/uc?export=download&id=1C-FpaGQA288dM5y40X1tpiNiN8EyNJKS'
    chmod a+x gowitness
fi
echo

# Onion Verifier
OV="/opt/darkfox/onion_verifier.py"
if [ -f "$OV" ]; then
    print_found "Onion Verifier"
else
    echo -e "\e[031mDownloading Onion Verifier\e[0m"
    wget --no-check-certificate -O onion_verifier.py 'https://github.com/aryanguenthner/darkfox/raw/refs/heads/main/onion_verifier.py'
    chmod a+x onion_verifier.py
fi
echo

# Verify TorGhost
TORNG="/usr/bin/torghostng"
if [ -f "$TORNG" ]; then
    print_found "TorghostNG"
else
    echo -e "\e[33mInstalling TorghostNG...\e[0m"
    if [ -d "/opt/torghostng" ]; then
        sudo rm -rf /opt/TorghostNG
    fi
    sudo git clone https://github.com/aryanguenthner/TorghostNG /opt/TorghostNG
    cd /opt/TorghostNG || exit
    sudo apt-get install -y python3-requests python3-stem python3-packaging
    [ ! -f /etc/sysctl.conf ] && sudo touch /etc/sysctl.conf
    sudo chmod +x install.py
    sudo python3 install.py
    if [ ! -f "/usr/bin/torghostng" ]; then
        sudo ln -sf /opt/TorghostNG/torghostng.py /usr/bin/torghostng
        sudo chmod +x /usr/bin/torghostng
    fi
    echo "TorghostNG installation attempt complete."
fi
echo

# Check/Install pyahmia
PYAHMIA_BIN=""
for candidate in "$(command -v pyahmia 2>/dev/null)" "$(command -v ahmia 2>/dev/null)" \
                 "/root/.local/bin/pyahmia" "/usr/local/bin/pyahmia" "/usr/bin/pyahmia"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        PYAHMIA_BIN="$candidate"
        break
    fi
done

if [ -n "$PYAHMIA_BIN" ]; then
    print_found "pyahmia: $PYAHMIA_BIN"
    "$PYAHMIA_BIN" -v 2>/dev/null || true
else
    echo -e "\e[33m[INSTALL]\e[0m pyahmia not found. Installing..."
    if command -v pipx >/dev/null 2>&1; then
        pipx install pyahmia
    else
        pip3 install --break-system-packages pyahmia 2>/dev/null || pip3 install pyahmia
    fi
    PYAHMIA_BIN="$(command -v pyahmia 2>/dev/null || command -v ahmia 2>/dev/null || true)"
    if [ -z "$PYAHMIA_BIN" ]; then
        for candidate in "/root/.local/bin/pyahmia" "/usr/local/bin/pyahmia"; do
            [ -x "$candidate" ] && PYAHMIA_BIN="$candidate" && break
        done
    fi
    if [ -n "$PYAHMIA_BIN" ] && [ -x "$PYAHMIA_BIN" ]; then
        echo -e "\e[32m[OK]\e[0m pyahmia installed: $PYAHMIA_BIN"
    else
        echo -e "\e[31m[FAILED]\e[0m Could not install/find pyahmia. Ahmia search will fail."
        exit 1
    fi
fi

# Firefox Configurations
FIREFOX_DIR="/home/kali/.mozilla/firefox"
if [ ! -d "$FIREFOX_DIR" ]; then
    echo "[+] Firefox profile not found. Initializing..."
    sudo -u kali firefox --headless >/dev/null 2>&1 &
    sleep 3
    sudo pkill firefox
fi

USER_JS_PATH=$(find /home/kali/.mozilla/firefox/ -name "user.js" 2>/dev/null | head -n 1)
if [[ -f "$USER_JS_PATH" ]]; then
    if ! grep -q 'user_pref("network.dns.blockDotOnion", false);' "$USER_JS_PATH"; then
        echo 'user_pref("network.dns.blockDotOnion", false);' >> "$USER_JS_PATH"
    fi
else
    sudo -u kali firefox >/dev/null 2>&1 &
    sleep 2
    sudo pkill firefox
    echo 'user_pref("network.dns.blockDotOnion", false);' > user.js
    sudo mv user.js /home/kali/.mozilla/firefox/*default-esr/
fi
echo

FIREFOX_POLICY_DIR="/etc/firefox-esr/policies"
mkdir -p "$FIREFOX_POLICY_DIR"
cat <<EOF > "$FIREFOX_POLICY_DIR/policies.json"
{
  "policies": {
    "Preferences": {
      "network.dns.blockDotOnion": {
        "Value": false,
        "Status": "locked"
      }
    }
  }
}
EOF
echo "[+] Firefox policy applied: network.dns.blockDotOnion = false"
echo

# User Input
read -e -p "What are you researching: " SEARCH

SAFE_SEARCH=$(echo "$SEARCH" | tr -c 'A-Za-z0-9._-' '_' | sed 's/__*/_/g' | sed 's/^_\|_$//g')
[ -z "$SAFE_SEARCH" ] && SAFE_SEARCH="search"

AHMIA_DIR="${HOME}/pyahmia"
mkdir -p "$AHMIA_DIR"
AHMIA_CSV="${PWD}/${SAFE_SEARCH}.csv"
RESULTS_FILE="${AHMIA_DIR}/${SAFE_SEARCH}.txt"

echo -e "\nSearching for: $SEARCH"
echo "Searching for DarkWeb Onions..."
echo -ne '#####                     (33%)\r'
sleep 1
echo -ne '#############             (66%)\r'
sleep 1
echo -ne '#######################   (100%)\r'
echo -ne '\n'
echo

# Query Ahmia
PYAHMIA_LOG="${AHMIA_DIR}/pyahmia_last.log"
if ! "$PYAHMIA_BIN" "$SEARCH" --export > "$PYAHMIA_LOG" 2>&1; then
    echo -e "\e[31m[WARN]\e[0m pyahmia exited with non-zero status. Log:"
    tail -20 "$PYAHMIA_LOG" 2>/dev/null || true
fi

if [ ! -f "$AHMIA_CSV" ]; then
    CANDIDATE=$(find "$AHMIA_DIR" -maxdepth 1 -name "*.csv" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)
    if [ -n "$CANDIDATE" ] && [ -f "$CANDIDATE" ]; then
        AHMIA_CSV="$CANDIDATE"
    fi
fi

if [ -f "$AHMIA_CSV" ]; then
    awk -F',' 'NR > 1 {
        for (i = 1; i <= NF; i++) {
            url = $i
            gsub(/"/, "", url)
            gsub(/^[ \t]+|[ \t]+$/, "", url)
            if (url ~ /\.onion/) {
                if (match(url, /[a-z2-7]{16,56}\.onion/)) {
                    print substr(url, RSTART, RLENGTH)
                } else {
                    print url
                }
            }
        }
    }' "$AHMIA_CSV" | sort -u > "$RESULTS_FILE"

    sed -i '/invest/d; /222/d; /drug/d; /porn/d; /darknet/d' "$RESULTS_FILE" 2>/dev/null || true
    COUNT=$(wc -l < "$RESULTS_FILE" | tr -d ' ')
    echo -e "\e[32mOnions Found:\e[0m $COUNT"
    echo "Results saved to: $RESULTS_FILE"
else
    echo -e "\e[31mNo CSV file created. Ahmia/pyahmia may have failed.\e[0m"
    COUNT=0
fi
echo

if [ "$COUNT" -eq 0 ]; then
    echo -e "\e[31mNo onion links found or candidate list empty. Exiting...\e[0m"
    exit 0
fi

# Tor Connection
echo -e "\e[32mFound $COUNT onion links candidate. Connecting to Tor...\e[0m"
sudo systemctl start tor
[ ! -f /etc/sysctl.conf ] && sudo touch /etc/sysctl.conf
sudo python3 /opt/TorghostNG/torghostng.py -id nl
echo

TOR_IP_JSON=$(curl --socks5-hostname 127.0.0.1:9050 -s --max-time 4 https://check.torproject.org/api/ip)
TOR_IP=$(echo "$TOR_IP_JSON" | jq -r '.IP // empty')
if [[ -n "$TOR_IP" ]]; then
    EXT="$TOR_IP"
    LOCATION=$(curl --socks5-hostname 127.0.0.1:9050 -s "http://ip-api.com/json/$EXT")
else
    EXT=$(curl -s https://api64.ipify.org || curl -s https://ifconfig.me || curl -s https://checkip.amazonaws.com)
    LOCATION=$(curl -s "http://ip-api.com/json/$EXT")
fi

COUNTRY=$(echo "$LOCATION" | jq -r '.country // "Unavailable"')
REGION=$(echo "$LOCATION" | jq -r '.regionName // "Unavailable"')
CITY=$(echo "$LOCATION" | jq -r '.city // "Unavailable"')
KALI=$(hostname -I | awk '{print $1}')

echo -e "\e[031mDarkweb Network Information\e[0m"
echo "---------------------------------"
printf "| %-12s | %-20s |\n" "Public IP" "$EXT"
printf "| %-12s | %-20s |\n" "Country" "$COUNTRY"
printf "| %-12s | %-20s |\n" "State" "$REGION"
printf "| %-12s | %-20s |\n" "City" "$CITY"
printf "| %-12s | %-20s |\n" "Kali IP" "$KALI"
echo "---------------------------------"
echo

# Prepare files for Onion Verifier
cd "$DARKFOX_DIR" || exit 1
CANDIDATES_FILE="$DARKFOX_DIR/candidates.onion.csv"
cp "$RESULTS_FILE" "$CANDIDATES_FILE"

echo -e "\e[31m[+] Verifying Onions live...\e[0m"
echo

# Run unbuffered (-u) so verifications stream to stdout immediately
# We tee to a logfile to parse live status
VERIFIER_LOG="$DARKFOX_DIR/onion_verifier.log"
sudo python3 -u "$DARKFOX_DIR/onion_verifier.py" "$CANDIDATES_FILE" | tee "$VERIFIER_LOG"
echo

# Filter reachable links into results.onion.csv
ONIONS_CSV="$DARKFOX_DIR/onion_page_titles.csv"
> "$DARKFOX_DIR/results.onion.csv"

if [ -f "$ONIONS_CSV" ] && [ -s "$ONIONS_CSV" ]; then
    # Extract only lines that have an HTTP 200 or valid extracted title (reachable)
    # Exclude failed rows containing "timed out", "down", "error", or "connection failed"
    awk -F',' 'NR > 1 && $1 ~ /\.onion/ && $0 !~ /(?i)(down|timed out|error|failed|404|502|503)/ {
        url = $1;
        gsub(/"/, "", url);
        gsub(/^[ \t]+|[ \t]+$/, "", url);
        if (match(url, /[a-z2-7]{16,56}\.onion/)) {
            print substr(url, RSTART, RLENGTH)
        }
    }' "$ONIONS_CSV" | sort -u > "$DARKFOX_DIR/results.onion.csv"
fi

# Fallback: Parse log if CSV filter produced no items
if [ ! -s "$DARKFOX_DIR/results.onion.csv" ] && [ -f "$VERIFIER_LOG" ]; then
    awk '/(?i)(alive|up|reachable|success|200)/ {
        for (i = 1; i <= NF; i++) {
            if (match($i, /[a-z2-7]{16,56}\.onion/)) {
                print substr($i, RSTART, RLENGTH)
            }
        }
    }' "$VERIFIER_LOG" | sort -u > "$DARKFOX_DIR/results.onion.csv"
fi

ALIVE_COUNT=$(wc -l < "$DARKFOX_DIR/results.onion.csv" | tr -d ' ')
echo -e "\e[32m[+] Reachable Onions Stored in DarkFox:\e[0m $ALIVE_COUNT"
echo

if [ "$ALIVE_COUNT" -eq 0 ]; then
    echo -e "\e[31mNo onion links were verified as reachable. Exiting early.\e[0m"
    sudo python3 /opt/TorghostNG/torghostng.py -x --dns > /dev/null 2>&1
    exit 0
fi

# Open reachable titles with LibreOffice
if [ -f "$ONIONS_CSV" ]; then
    echo -e "\e[031mOpening DarkFox results with LibreOffice\e[0m"
    sudo libreoffice --calc "$ONIONS_CSV" --infilter="CSV:44,34,0,1,4/2/1" --norestore > /dev/null 2>&1 & disown
fi

# Open top 3 reachable sites in Firefox
readarray -t HITS < <(head -n 3 "$DARKFOX_DIR/results.onion.csv")
echo "Opening Reachable Dark Web Sites in Firefox..."
for HIT in "${HITS[@]}"; do
    if [ -n "$HIT" ]; then
        sudo -u kali firefox "http://$HIT" > /dev/null 2>&1 & disown
        sleep 2
    fi
done

# Run gowitness only on the reachable results
echo -e "\e[31mGoWitness Getting Screenshots for reachable onions...\e[0m"
sudo ./gowitness scan file -f "$DARKFOX_DIR/results.onion.csv" \
    --threads 8 \
    --write-db \
    --screenshot-fullpage \
    --chrome-proxy socks5://127.0.0.1:9050 \
    2>&1 | grep -Ev "ERROR|unknown IPAddressSpace value: Loopback"

echo
echo -e "\e[31mScreenshot capture complete\e[0m"
echo

# Start Web Server & Open Gallery
echo "Starting GoWitness Server..."
sudo qterminal -e ./gowitness report server > /dev/null 2>&1 & disown
sleep 2

GOSERVER="http://127.0.0.1:7171/gallery"
sudo -u kali firefox "$GOSERVER" > /dev/null 2>&1 & disown
sleep 2
sudo xdotool search --onlyvisible --class firefox windowactivate --sync key Ctrl+r 2>/dev/null || true

# Teardown / Disconnect Option
echo
read -p "Do you want to disconnect from the dark web? (y/n): " DISCONNECT
echo

if [[ "$DISCONNECT" == "y" || "$DISCONNECT" == "Y" ]]; then
    echo "Exiting Dark Web..."
    sudo python3 /opt/TorghostNG/torghostng.py -x --dns
    echo nameserver 1.1.1.1 | sudo tee /etc/resolv.conf > /dev/null
    echo nameserver 8.8.8.8 | sudo tee -a /etc/resolv.conf > /dev/null

    if command -v systemd-resolve >/dev/null 2>&1; then
        sudo systemd-resolve --flush-caches
    elif command -v resolvectl >/dev/null 2>&1; then
        sudo resolvectl flush-caches
    fi

    echo "=== Done! Welcome back to the real world. ==="
fi
