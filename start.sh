#!/bin/bash

echo "=========================================="
echo "🚀 Starting Chrome Cloud RDP"
echo "=========================================="

# Environment variables are mostly set in the Dockerfile
export DISPLAY=:99
export VNC_PORT=5900
export WEB_PORT=80

# Start X Virtual Framebuffer
echo "Starting Xvfb on display ${DISPLAY}..."
Xvfb :99 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x24 -ac -noreset &
sleep 2

# Start Window Manager
echo "Starting Fluxbox..."
fluxbox &
sleep 1

# Start VNC Server (x11vnc)
echo "Starting VNC server on localhost:${VNC_PORT} with -ncache 10..."
# Added -ncache 10 for performance
x11vnc -display :99 -forever -shared -nopw -listen localhost -xkb -ncache 10 & 
sleep 2

# Start Chrome Browser
echo "Starting Chrome with Google Colab..."
google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --window-size=${DISPLAY_WIDTH},${DISPLAY_HEIGHT} \
    --start-maximized \
    "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &
sleep 5

# Start noVNC/websockify (Serves /usr/share/novnc and proxies to VNC)
echo "Starting websockify (noVNC server) on port ${WEB_PORT}..."
websockify --web /usr/share/novnc/ ${WEB_PORT} localhost:${VNC_PORT}

echo "=========================================="
echo "✅ Chrome RDP is READY! Access on port ${WEB_PORT}"
echo "=========================================="

# Keep the container running
wait
