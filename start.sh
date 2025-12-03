#!/bin/bash

echo "=========================================="
echo "🚀 Starting Chrome Cloud RDP"
echo "=========================================="

# Set variables
export DISPLAY=:99
WIDTH=1280
HEIGHT=720
VNC_PASSWORD=${VNC_PASSWORD:-chrome123}

echo "Display: ${WIDTH}x${HEIGHT}"
echo "VNC Password: $VNC_PASSWORD"

# Kill existing processes
pkill -f Xvfb 2>/dev/null || true
pkill -f x11vnc 2>/dev/null || true
pkill -f websockify 2>/dev/null || true
pkill -f chrome 2>/dev/null || true

# Fix X11 permissions
rm -rf /tmp/.X11-unix /tmp/.X0-lock
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Start Xvfb
echo "Starting Xvfb..."
Xvfb :99 -screen 0 ${WIDTH}x${HEIGHT}x24 -ac +extension GLX +render -noreset &
sleep 2

# Start fluxbox
echo "Starting window manager..."
fluxbox &
sleep 1

# Fix X11 auth - IMPORTANT!
xauth generate :99 . trusted
xhost +local:

# Start VNC with auth fix
echo "Starting VNC server..."
if [ "$VNC_PASSWORD" != "chrome123" ]; then
    mkdir -p ~/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd
    x11vnc -display :99 -forever -shared -rfbauth ~/.vnc/passwd -listen localhost -auth guess &
else
    x11vnc -display :99 -forever -shared -nopw -listen localhost -auth guess &
fi
sleep 2

# Start Chrome (no sudo needed)
echo "Starting Chrome with Google Colab..."
google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --window-size=${WIDTH},${HEIGHT} \
    --start-maximized \
    --user-data-dir=/home/chrome/.config/google-chrome \
    --no-first-run \
    --no-default-browser-check \
    "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &
CHROME_PID=$!
sleep 5

# Verify Chrome
if ps -p $CHROME_PID > /dev/null; then
    echo "✅ Chrome started (PID: $CHROME_PID)"
else
    echo "⚠️ Chrome may have issues, but continuing..."
fi

# Start noVNC
echo "Starting noVNC..."
cd /usr/share/novnc
./utils/novnc_proxy --vnc localhost:5900 --listen 80 &

# Create health check
echo "OK" > /usr/share/novnc/health.html

# Create simple status page
cat > /usr/share/novnc/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Chrome RDP - Ready!</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #0d1117 0%, #161b22 100%);
            color: white;
            margin: 0;
            padding: 20px;
            min-height: 100vh;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            text-align: center;
            padding: 40px;
            background: rgba(255,255,255,0.05);
            border-radius: 15px;
            border: 1px solid #30363d;
        }
        h1 {
            color: #58a6ff;
            font-size: 2.5em;
            margin-bottom: 20px;
        }
        .btn {
            display: inline-block;
            background: #238636;
            color: white;
            padding: 15px 30px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: bold;
            margin: 10px;
            border: none;
            cursor: pointer;
            font-size: 1.1em;
        }
        .btn:hover {
            background: #2ea043;
        }
        .status {
            background: rgba(88, 166, 255, 0.1);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            border-left: 4px solid #58a6ff;
        }
        .url-box {
            background: rgba(255, 165, 0, 0.1);
            border: 1px solid #FFA500;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
            font-family: monospace;
            word-break: break-all;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Chrome Cloud RDP</h1>
        <p>Your browser with Google Colab is ready!</p>
        
        <div class="status">
            <p><strong>✅ System Status:</strong> Online</p>
            <p><strong>🔑 VNC Password:</strong> chrome123</p>
            <p><strong>🖥️ Display:</strong> 1280x720</p>
        </div>
        
        <div class="url-box">
            <strong>Your Colab Notebook:</strong><br>
            https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1
        </div>
        
        <a href="/vnc_lite.html" class="btn">🚀 Connect to VNC</a>
        <a href="https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1" 
           target="_blank" class="btn" style="background: #FFA500;">
           📒 Open Colab Directly
        </a>
        
        <p style="margin-top: 30px; color: #8b949e;">
            After connecting via VNC, you'll see Chrome with your notebook already loaded.
        </p>
    </div>
</body>
</html>
EOF

echo "=========================================="
echo "✅ Setup Complete!"
echo "🌐 Access: http://localhost"
echo "🔗 VNC: http://localhost/vnc_lite.html"
echo "📒 Colab: Pre-loaded in Chrome"
echo "=========================================="

# Keep container running
tail -f /dev/null
