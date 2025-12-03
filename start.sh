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

# Start DBUS to suppress Chrome errors
mkdir -p /run/dbus
dbus-daemon --system --fork 2>/dev/null || true

# Start Xvfb
echo "Starting Xvfb..."
Xvfb :99 -screen 0 ${WIDTH}x${HEIGHT}x24 -ac +extension GLX +render -noreset &
sleep 3

# Set display
export DISPLAY=:99

# Fix X11 auth
touch /root/.Xauthority
xauth generate :99 . trusted
xhost +local: 2>/dev/null || true

# Start fluxbox
echo "Starting window manager..."
fluxbox &
sleep 2

# Start VNC
echo "Starting VNC server..."
if [ "$VNC_PASSWORD" != "chrome123" ]; then
    mkdir -p ~/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd
    x11vnc -display :99 -forever -shared -rfbauth ~/.vnc/passwd -listen localhost -auth guess &
else
    x11vnc -display :99 -forever -shared -nopw -listen localhost -auth guess &
fi
sleep 3

# Start Chrome with DBUS errors suppressed
echo "Starting Chrome with Google Colab..."
google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-extensions \
    --disable-background-networking \
    --disable-sync \
    --disable-default-apps \
    --disable-translate \
    --disable-features=site-per-process,TranslateUI,BlinkGenPropertyTrees \
    --window-size=${WIDTH},${HEIGHT} \
    --window-position=0,0 \
    --start-maximized \
    --user-data-dir=/home/chrome/.config/google-chrome \
    --no-first-run \
    --no-default-browser-check \
    --disable-component-update \
    --disable-breakpad \
    "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" > /dev/null 2>&1 &
CHROME_PID=$!
sleep 5

# Verify Chrome
if ps -p $CHROME_PID > /dev/null 2>&1; then
    echo "✅ Chrome started (PID: $CHROME_PID)"
else
    echo "⚠️ Chrome may have issues, trying alternative method..."
    # Try without some flags
    google-chrome-stable \
        --no-sandbox \
        --disable-dev-shm-usage \
        "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &
    sleep 5
fi

# Start noVNC properly
echo "Starting noVNC web interface..."
cd /opt/noVNC

# Create a simple launcher script for noVNC
cat > /tmp/start_novnc.sh << 'EOF'
#!/bin/bash
cd /opt/noVNC
python3 ./utils/novnc_proxy --vnc localhost:5900 --listen 0.0.0.0:80
EOF
chmod +x /tmp/start_novnc.sh

# Start noVNC in background
/tmp/start_novnc.sh > /var/log/novnc.log 2>&1 &
NOVNC_PID=$!
sleep 3

# Verify noVNC is running
if ps -p $NOVNC_PID > /dev/null 2>&1; then
    echo "✅ noVNC started (PID: $NOVNC_PID)"
else
    echo "⚠️ Starting alternative noVNC method..."
    # Alternative method
    cd /opt/noVNC/utils/websockify
    python3 -m websockify --web /opt/noVNC 80 localhost:5900 &
fi

# Create simple redirect page
cat > /opt/noVNC/redirect.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Chrome RDP - Loading...</title>
    <meta http-equiv="refresh" content="3;url=/vnc_lite.html">
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #0d1117;
            color: white;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            text-align: center;
        }
        .loader {
            border: 5px solid #f3f3f3;
            border-top: 5px solid #58a6ff;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div>
        <div class="loader"></div>
        <h1>Chrome RDP</h1>
        <p>Redirecting to VNC client...</p>
        <p>If not redirected in 5 seconds, <a href="/vnc_lite.html">click here</a></p>
    </div>
</body>
</html>
EOF

# Create health check
echo "OK" > /opt/noVNC/health.html

# Copy vnc_lite.html to root
if [ -f /opt/noVNC/vnc_lite.html ]; then
    cp /opt/noVNC/vnc_lite.html /opt/noVNC/index.html
fi

echo "=========================================="
echo "✅ Setup Complete!"
echo "🌐 Access: https://$(hostname)"
echo "🔗 Direct VNC: /vnc_lite.html"
echo "🔑 VNC Password: $VNC_PASSWORD (or leave blank)"
echo "📒 Your Colab is pre-loaded in Chrome"
echo "=========================================="

# Show connection URL
echo ""
echo "📡 Waiting for connections..."
echo ""

# Keep container running and show logs
tail -f /var/log/novnc.log 2>/dev/null || sleep infinity
