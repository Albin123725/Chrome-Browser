#!/bin/bash

echo "========================================="
echo "Starting Chrome Cloud RDP - Optimized"
echo "========================================="

# Set environment variables
DISPLAY_WIDTH=${DISPLAY_WIDTH:-1280}
DISPLAY_HEIGHT=${DISPLAY_HEIGHT:-720}
VNC_PASSWORD=${VNC_PASSWORD:-chrome123}
STARTUP_URL=${STARTUP_URL:-https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing}

# Create necessary directories
mkdir -p /data/chrome /data/downloads /home/chrome/.config
chown -R chrome:chrome /data /home/chrome

# Fix DBus errors by disabling it
export DBUS_SESSION_BUS_ADDRESS=/dev/null
export NO_AT_BRIDGE=1

# Start Xvfb (virtual display)
Xvfb :99 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99

# Start Fluxbox (window manager)
fluxbox &

# Start VNC server
x11vnc -display :99 -forever -shared -nopw -listen localhost -xkb &

# Start Chrome with OPTIMIZED flags to suppress errors
echo "Starting Chrome with optimized flags..."
sudo -u chrome google-chrome-stable \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --disable-software-rasterizer \
  --disable-features=VizDisplayCompositor \
  --disable-background-networking \
  --disable-sync \
  --disable-default-apps \
  --disable-translate \
  --disable-component-update \
  --disable-breakpad \
  --disable-crash-reporter \
  --disable-domain-reliability \
  --disable-features=AudioServiceOutOfProcess,MediaSessionService \
  --disable-background-timer-throttling \
  --disable-backgrounding-occluded-windows \
  --disable-renderer-backgrounding \
  --disable-ipc-flooding-protection \
  --disable-client-side-phishing-detection \
  --disable-component-extensions-with-background-pages \
  --disable-popup-blocking \
  --enable-automation \
  --password-store=basic \
  --use-mock-keychain \
  --no-first-run \
  --no-default-browser-check \
  --remote-debugging-port=9222 \
  --window-size=${DISPLAY_WIDTH},${DISPLAY_HEIGHT} \
  --start-maximized \
  --user-data-dir=/data/chrome \
  --disable-web-security \
  --allow-running-insecure-content \
  --disable-site-isolation-trials \
  --disable-features=IsolateOrigins,site-per-process \
  --disable-blink-features=AutomationControlled \
  --metrics-recording-only \
  --disable-extensions \
  --mute-audio \
  --no-zygote \
  --no-pings \
  --no-service-autorun \
  --disable-hang-monitor \
  --disable-prompt-on-repost \
  --disable-device-discovery-notifications \
  --disable-component-update \
  --disable-background-downloads \
  "$STARTUP_URL" &

# Save Chrome PID
CHROME_PID=$!
echo "Chrome started with PID: $CHROME_PID"

# Function to keep system alive
keep_alive() {
    while true; do
        echo "[$(date)] System alive - Chrome PID: $CHROME_PID"
        
        # Check if Chrome is running
        if ! kill -0 $CHROME_PID 2>/dev/null; then
            echo "Chrome stopped, but that's OK in container mode"
        fi
        
        # Send a simple keep-alive to prevent Render sleep
        curl -s https://${RENDER_SERVICE_NAME}.onrender.com/health > /dev/null 2>&1 || true
        
        sleep 60
    done
}

# Start keep-alive in background
keep_alive &

# Start noVNC (web interface)
websockify --web /usr/share/novnc/ 6080 localhost:5900 &

# Start Nginx
nginx -g "daemon off;"

echo "========================================="
echo "Chrome RDP is READY!"
echo "Access at: https://${RENDER_SERVICE_NAME}.onrender.com"
echo "========================================="

# Keep container running
wait
