#!/bin/bash

echo "=========================================="
echo "🚀 Starting Chrome Cloud RDP with Google Colab"
echo "=========================================="

# Clean up previous X11 locks
rm -rf /tmp/.X11-unix /tmp/.X*-lock
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Set display
export DISPLAY=:99
export DISPLAY_WIDTH=1280
export DISPLAY_HEIGHT=720
export VNC_PASSWORD=${VNC_PASSWORD:-}

echo "📊 Display: ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}"
echo "🔑 VNC Password: ${VNC_PASSWORD:-none}"

# Kill any existing processes
pkill -f Xvfb 2>/dev/null || true
pkill -f x11vnc 2>/dev/null || true
pkill -f fluxbox 2>/dev/null || true
pkill -f chrome 2>/dev/null || true

# Create Xauthority file
touch /root/.Xauthority
xauth add :99 . $(mcookie)

# Start Xvfb (virtual display)
echo "🖥️  Starting virtual display..."
Xvfb :99 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 3

# Verify Xvfb started
if ! kill -0 $XVFB_PID 2>/dev/null; then
    echo "❌ Xvfb failed to start"
    exit 1
fi

# Set X permissions
xhost +local: > /dev/null 2>&1

# Start window manager
echo "🪟 Starting window manager..."
fluxbox &
sleep 2

# Start VNC server
echo "🔌 Starting VNC server..."
if [ -n "$VNC_PASSWORD" ]; then
    echo "Using password authentication"
    mkdir -p ~/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd
    x11vnc -display :99 -forever -shared -rfbauth ~/.vnc/passwd -listen localhost -xkb &
else
    echo "Using no password"
    x11vnc -display :99 -forever -shared -nopw -listen localhost -xkb &
fi
VNC_PID=$!
sleep 3

# Verify VNC started
if ! kill -0 $VNC_PID 2>/dev/null; then
    echo "❌ VNC server failed to start, trying alternative method..."
    # Try with auth file
    touch /tmp/.X99-lock
    x11vnc -display :99 -forever -shared -nopw -listen localhost -auth /tmp/.X99-lock &
    VNC_PID=$!
    sleep 3
fi

if ! kill -0 $VNC_PID 2>/dev/null; then
    echo "❌ VNC server still failed to start"
    exit 1
fi

# Start Chrome with Google Colab
echo "🌐 Starting Chrome with your Colab notebook..."
google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --disable-software-rasterizer \
    --window-size=${DISPLAY_WIDTH},${DISPLAY_HEIGHT} \
    --window-position=0,0 \
    --user-data-dir=/tmp/chrome-data \
    --no-first-run \
    --no-default-browser-check \
    --disable-background-networking \
    --disable-sync \
    --disable-default-apps \
    "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &
CHROME_PID=$!
sleep 5

# Verify Chrome started
if kill -0 $CHROME_PID 2>/dev/null; then
    echo "✅ Chrome running (PID: $CHROME_PID)"
else
    echo "⚠️ Chrome may have issues but continuing..."
fi

# Create simple web interface
echo "🎨 Creating web interface..."
cat > /usr/share/novnc/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Chrome RDP - Ready</title>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0;url=vnc_lite.html">
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
        .container {
            padding: 40px;
            background: rgba(255,255,255,0.05);
            border-radius: 15px;
            border: 1px solid #30363d;
            max-width: 500px;
        }
        .loader {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #58a6ff;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .btn {
            display: inline-block;
            background: #238636;
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            text-decoration: none;
            margin-top: 20px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Chrome Cloud RDP</h1>
        <p>Your browser with Google Colab is ready!</p>
        
        <div class="loader"></div>
        
        <p>Redirecting to VNC client...</p>
        <p>If not redirected, click below:</p>
        
        <a href="vnc_lite.html" class="btn">🚀 Launch VNC Client</a>
    </div>
</body>
</html>
EOF

# Create health check
echo "OK" > /usr/share/novnc/health

echo ""
echo "=========================================="
echo "✅ SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "🌐 ACCESS:"
echo "   Main URL: https://$(hostname)/"
echo "   VNC Client: https://$(hostname)/vnc_lite.html"
echo "   Health Check: https://$(hostname)/health"
echo ""
echo "🔧 INFO:"
echo "   VNC Password: ${VNC_PASSWORD:-none (leave blank)}"
echo "   Display: ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}"
echo ""
echo "🖱️  INSTRUCTIONS:"
echo "   1. Visit the main URL above"
echo "   2. Click 'Launch VNC Client'"
echo "   3. Click 'Connect' in VNC interface"
echo "   4. Your Colab notebook will be open in Chrome"
echo ""
echo "=========================================="

# Start noVNC
echo "🌐 Starting noVNC web interface..."
websockify --web /usr/share/novnc 80 localhost:5900
