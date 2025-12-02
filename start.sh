#!/bin/bash

echo "========================================="
echo "Starting Chrome Cloud RDP - Persistent Mode"
echo "========================================="

# Set environment variables
DISPLAY_WIDTH=${DISPLAY_WIDTH:-1280}
DISPLAY_HEIGHT=${DISPLAY_HEIGHT:-720}
VNC_PASSWORD=${VNC_PASSWORD:-chrome123}
STARTUP_URL=${STARTUP_URL:-https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing}

# Start Xvfb (virtual display)
Xvfb :99 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99

# Start Fluxbox (window manager)
fluxbox &

# Start VNC server
x11vnc -display :99 -forever -shared -nopw -listen localhost -xkb &

# Start Chrome in HEADLESS MODE for background tasks
echo "Starting Chrome in persistent mode..."
google-chrome-stable \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --remote-debugging-port=9222 \
  --window-size=${DISPLAY_WIDTH},${DISPLAY_HEIGHT} \
  --start-maximized \
  --user-data-dir=/data/chrome \
  --no-first-run \
  --no-default-browser-check \
  --disable-sync \
  --disable-background-timer-throttling \
  --disable-renderer-backgrounding \
  --disable-backgrounding-occluded-windows \
  --disable-ipc-flooding-protection \
  --enable-logging \
  --v=1 \
  "$STARTUP_URL" &

# Save Chrome PID to keep it running
CHROME_PID=$!
echo "Chrome started with PID: $CHROME_PID"

# Function to keep Chrome alive
keep_chrome_alive() {
    while true; do
        if ! kill -0 $CHROME_PID 2>/dev/null; then
            echo "Chrome crashed, restarting..."
            google-chrome-stable \
                --no-sandbox \
                --disable-dev-shm-usage \
                --disable-gpu \
                --remote-debugging-port=9222 \
                --window-size=${DISPLAY_WIDTH},${DISPLAY_HEIGHT} \
                --start-maximized \
                --user-data-dir=/data/chrome \
                "$STARTUP_URL" &
            CHROME_PID=$!
            echo "Chrome restarted with PID: $CHROME_PID"
        fi
        
        # Check if any tab is running Colab
        curl -s http://localhost:9222/json/list | grep -q "colab.research.google.com" \
            && echo "Colab notebook is running..." \
            || echo "No Colab tabs found"
        
        sleep 30
    done
}

# Start Chrome monitor in background
keep_chrome_alive &

# Start noVNC (web interface)
websockify --web /usr/share/novnc/ 6080 localhost:5900 &

# Start Nginx
nginx -g "daemon off;"

echo "Setup complete! Chrome will continue running even when you disconnect."
