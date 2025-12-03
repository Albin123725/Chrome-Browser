#!/bin/bash

echo "🚀 Starting Chrome RDP..."

# Start Xvfb
Xvfb :99 -screen 0 1280x720x24 &
export DISPLAY=:99

# Start fluxbox
fluxbox &

# Start VNC
x11vnc -display :99 -forever -shared -nopw -listen localhost &

# Start Chrome with Colab
google-chrome-stable --no-sandbox --disable-dev-shm-usage \
    --window-size=1280,720 \
    "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &

# Start Node.js server (for Render health checks)
node server.js &

# Start noVNC
websockify --web /usr/share/novnc 80 localhost:5900

# Keep running
wait
