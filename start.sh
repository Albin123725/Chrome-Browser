#!/bin/bash

echo "========================================="
echo "Starting Chrome Cloud RDP"
echo "========================================="

# Load environment variables with defaults
DISPLAY_WIDTH=${DISPLAY_WIDTH:-1280}
DISPLAY_HEIGHT=${DISPLAY_HEIGHT:-720}
VNC_PASSWORD=${VNC_PASSWORD:-chrome123}
ENABLE_AUTH=${ENABLE_AUTH:-false}
AUTH_USER=${AUTH_USER:-admin}
AUTH_PASS=${AUTH_PASS:-admin123}
STARTUP_URL=${STARTUP_URL:-https://colab.research.google.com}

echo "Configuration:"
echo "- Display: ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}"
echo "- VNC Password: ${VNC_PASSWORD:0:3}**** (set via env)"
echo "- Auth Enabled: ${ENABLE_AUTH}"
echo "- Startup URL: ${STARTUP_URL}"
echo ""

# Set VNC password if provided
if [ -n "$VNC_PASSWORD" ] && [ "$VNC_PASSWORD" != "chrome123" ]; then
    echo "Setting VNC password..."
    mkdir -p ~/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd
fi

# Set up HTTP authentication if enabled
if [ "$ENABLE_AUTH" = "true" ]; then
    echo "Setting up HTTP authentication..."
    htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASS"
    sed -i 's/# auth_basic/auth_basic/g' /etc/nginx/nginx.conf
    sed -i 's/# auth_basic_user_file/auth_basic_user_file/g' /etc/nginx/nginx.conf
fi

# Create Chrome data directory with proper permissions
echo "Setting up Chrome data directory..."
mkdir -p /data/chrome /data/downloads
chown -R chrome:chrome /data

# Update Chrome flags with display size
export CHROME_FLAGS="--user-data-dir=/data/chrome --no-first-run --no-default-browser-check --disable-sync --disable-blink-features=AutomationControlled --window-size=${DISPLAY_WIDTH},${DISPLAY_HEIGHT}"

# Set display environment
export DISPLAY=:99

# Create startup script for Chrome
if [ -n "$STARTUP_URL" ]; then
    cat > /home/chrome/startup.sh << EOF
#!/bin/bash
sleep 3
# Open startup URL
google-chrome-stable --no-sandbox --disable-dev-shm-usage "$STARTUP_URL" &
# Open new tab with helpful links
sleep 5
google-chrome-stable --new-window "https://www.google.com" "https://github.com" "https://colab.research.google.com" &
EOF
    chmod +x /home/chrome/startup.sh
    chown chrome:chrome /home/chrome/startup.sh
fi

echo "Starting services via Supervisor..."
echo ""

# Start Supervisor (which starts all services)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
