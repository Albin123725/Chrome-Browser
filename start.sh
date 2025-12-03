#!/bin/bash

echo "=========================================="
echo "🚀 Starting Chrome Cloud RDP"
echo "=========================================="

# Set environment variables
export DISPLAY=:99
export DISPLAY_WIDTH=1280
export DISPLAY_HEIGHT=720
export VNC_PASSWORD=${VNC_PASSWORD:-chrome123}

echo "Display: ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}"
echo "VNC Password: ${VNC_PASSWORD}"

# Kill any existing processes to avoid conflicts
echo "Cleaning up existing processes..."
pkill -f Xvfb 2>/dev/null || true
pkill -f x11vnc 2>/dev/null || true
pkill -f websockify 2>/dev/null || true
pkill -f chrome 2>/dev/null || true

# Create necessary directories
mkdir -p /data/chrome /data/downloads /tmp/.X11-unix
chown -R chrome:chrome /data /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Start X Virtual Framebuffer
echo "Starting Xvfb..."
Xvfb :99 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 2

# Start Window Manager
echo "Starting Fluxbox..."
fluxbox &
sleep 1

# Start VNC Server
echo "Starting VNC server..."
if [ -n "$VNC_PASSWORD" ] && [ "$VNC_PASSWORD" != "chrome123" ]; then
    echo "Setting VNC password..."
    mkdir -p ~/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd
    x11vnc -display :99 -forever -shared -rfbauth ~/.vnc/passwd -listen localhost -xkb &
else
    x11vnc -display :99 -forever -shared -nopw -listen localhost -xkb &
fi
sleep 2

# Start Chrome Browser (as non-root user)
echo "Starting Chrome with Google Colab..."
sudo -u chrome google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --disable-software-rasterizer \
    --remote-debugging-port=9222 \
    --window-size=${DISPLAY_WIDTH},${DISPLAY_HEIGHT} \
    --start-maximized \
    --user-data-dir=/data/chrome \
    --no-first-run \
    --no-default-browser-check \
    --disable-background-timer-throttling \
    --disable-renderer-backgrounding \
    --disable-backgrounding-occluded-windows \
    --disable-ipc-flooding-protection \
    --disable-features=VizDisplayCompositor \
    --disable-sync \
    --disable-default-apps \
    --disable-breakpad \
    --disable-crash-reporter \
    --password-store=basic \
    --use-mock-keychain \
    "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &
CHROME_PID=$!
sleep 5

# Verify Chrome started
if kill -0 $CHROME_PID 2>/dev/null; then
    echo "✅ Chrome started successfully (PID: $CHROME_PID)"
else
    echo "❌ Chrome failed to start"
fi

# Start noVNC Web Interface
echo "Starting noVNC web interface..."
cd /opt/noVNC
./utils/novnc_proxy --vnc localhost:5900 --listen 80 &
NOVNC_PID=$!
sleep 2

# Create a simple status page
cat > /opt/noVNC/status.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Chrome RDP Status</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 40px; background: #0d1117; color: white; text-align: center; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #58a6ff; }
        .status { background: #161b22; padding: 20px; border-radius: 10px; margin: 20px 0; }
        .online { color: #2ea043; }
        .btn { background: #238636; color: white; padding: 12px 24px; border: none; border-radius: 6px; cursor: pointer; margin: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Chrome Cloud RDP</h1>
        <div class="status">
            <h2 class="online">✅ System is Online</h2>
            <p>Chrome PID: $CHROME_PID</p>
            <p>VNC Server: Running on port 5900</p>
            <p>Web Interface: Ready</p>
        </div>
        <button class="btn" onclick="window.location.href='/vnc_lite.html'">
            Connect to VNC
        </button>
        <button class="btn" onclick="window.open('https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1', '_blank')">
            Open Colab Directly
        </button>
        <p style="margin-top: 30px; color: #8b949e;">
            Your notebook is pre-loaded in Chrome. Connect via VNC above.
        </p>
    </div>
</body>
</html>
EOF

# Create health endpoint
echo "OK" > /opt/noVNC/health.html

echo "=========================================="
echo "✅ Chrome RDP is fully operational!"
echo "🌐 Access at: http://localhost"
echo "🔗 VNC Client: http://localhost/vnc_lite.html"
echo "📊 Status: http://localhost/status.html"
echo "❤️  Health: http://localhost/health.html"
echo "🔑 VNC Password: $VNC_PASSWORD"
echo "=========================================="

# Monitor processes and keep container alive
echo "Starting process monitor..."
while true; do
    # Check if Xvfb is running
    if ! kill -0 $XVFB_PID 2>/dev/null; then
        echo "❌ Xvfb died, restarting..."
        Xvfb :99 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x24 -ac +extension GLX +render -noreset &
        XVFB_PID=$!
    fi
    
    # Check if Chrome is running
    if ! kill -0 $CHROME_PID 2>/dev/null; then
        echo "⚠️ Chrome died, restarting..."
        sudo -u chrome google-chrome-stable \
            --no-sandbox \
            --disable-dev-shm-usage \
            --window-size=${DISPLAY_WIDTH},${DISPLAY_HEIGHT} \
            --start-maximized \
            --user-data-dir=/data/chrome \
            "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &
        CHROME_PID=$!
    fi
    
    # Check if noVNC is running
    if ! kill -0 $NOVNC_PID 2>/dev/null; then
        echo "⚠️ noVNC died, restarting..."
        cd /opt/noVNC
        ./utils/novnc_proxy --vnc localhost:5900 --listen 80 &
        NOVNC_PID=$!
    fi
    
    # Sleep and continue monitoring
    sleep 30
done            border: 1px solid #FFA500;
            border-radius: 8px;
            padding: 15px;
            margin: 15px 0;
            font-family: monospace;
            font-size: 0.9rem;
            word-break: break-all;
            color: #FFA500;
        }
        footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #30363d;
            color: #8b949e;
            font-size: 0.9rem;
        }
        .status {
            display: inline-block;
            width: 10px;
            height: 10px;
            background: #2ea043;
            border-radius: 50%;
            margin-right: 8px;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
    <div class="container">
        <header>
            <h1><i class="fas fa-cloud"></i> Chrome Cloud RDP</h1>
            <p class="subtitle">Access your Chrome browser with Google Colab in the cloud</p>
            <p><span class="status"></span> System is running</p>
        </header>
        
        <div class="content">
            <div class="panel">
                <h2><i class="fas fa-desktop"></i> Remote Desktop</h2>
                <p>Connect to your Chrome browser using the VNC client below:</p>
                <iframe class="vnc-frame" src="/vnc_lite.html" id="vnc-frame"></iframe>
                <div style="margin-top: 15px; text-align: center;">
                    <button class="btn" onclick="document.getElementById('vnc-frame').src = '/vnc_lite.html'">
                        <i class="fas fa-sync"></i> Reconnect
                    </button>
                    <button class="btn btn-secondary" onclick="window.open('/vnc_lite.html', '_blank')">
                        <i class="fas fa-external-link-alt"></i> Open in New Tab
                    </button>
                </div>
            </div>
            
            <div class="panel">
                <h2><i class="fab fa-google"></i> Google Colab Notebook</h2>
                <p>Your personal notebook is pre-loaded in Chrome:</p>
                <div class="colab-url">
                    https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1
                </div>
                <div class="info-box">
                    <p><i class="fas fa-info-circle"></i> After connecting via VNC:</p>
                    <ol style="margin-left: 20px; margin-top: 10px;">
                        <li>Click on the Chrome window</li>
                        <li>Your Colab notebook is already open</li>
                        <li>Start coding immediately!</li>
                    </ol>
                </div>
                <button class="btn" onclick="window.open('https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1', '_blank')">
                    <i class="fas fa-external-link-alt"></i> Open Colab Directly
                </button>
            </div>
        </div>
        
        <div class="panel">
            <h2><i class="fas fa-terminal"></i> Quick Actions</h2>
            <div style="display: flex; flex-wrap: wrap; gap: 10px; margin-top: 15px;">
                <button class="btn" onclick="location.reload()">
                    <i class="fas fa-redo"></i> Refresh Page
                </button>
                <button class="btn btn-secondary" onclick="alert('VNC Password: chrome123 (or check logs)')">
                    <i class="fas fa-key"></i> Show VNC Password
                </button>
                <button class="btn btn-secondary" onclick="window.open('/health', '_blank')">
                    <i class="fas fa-heartbeat"></i> Health Check
                </button>
            </div>
        </div>
        
        <footer>
            <p>Chrome Cloud RDP • Running on Render • Your notebook: 1jckV8xUJSmLhhol6wZwVJzpybsimiRw1</p>
            <p style="margin-top: 10px; font-size: 0.8rem;">
                <i class="fas fa-shield-alt"></i> Secure connection • 
                <i class="fas fa-bolt"></i> Fast performance • 
                <i class="fas fa-infinity"></i> Persistent session
            </p>
        </footer>
    </div>
    
    <script>
        // Auto-reconnect if VNC disconnects
        setInterval(() => {
            const frame = document.getElementById('vnc-frame');
            try {
                if (!frame.contentWindow || frame.contentWindow.closed) {
                    console.log('VNC disconnected, reconnecting...');
                    frame.src = frame.src;
                }
            } catch (e) {
                // Cross-origin error, ignore
            }
        }, 10000);
        
        // Show connection status
        console.log('Chrome RDP loaded successfully!');
        console.log('Your Colab notebook is pre-loaded in Chrome');
    </script>
</body>
</html>
EOF

# Also create vnc_lite.html if missing
if [ ! -f /usr/share/novnc/vnc_lite.html ]; then
    echo "Creating VNC client page..."
    cat > /usr/share/novnc/vnc_lite.html << 'EOF2'
<!DOCTYPE html>
<html>
<head>
    <title>noVNC VNC Client</title>
    <meta charset="UTF-8">
    <script src="./app/ui.js"></script>
    <link rel="stylesheet" href="./app/styles/base.css">
</head>
<body>
    <div id="noVNC_screen">
        <div id="noVNC_control_bar">
            <div id="noVNC_control_bar_handle"></div>
            <img src="./app/images/novnc-logo.svg" alt="noVNC logo" id="noVNC_logo">
            <input type="button" id="noVNC_connect_button" value="Connect">
            <input type="button" id="noVNC_disconnect_button" value="Disconnect">
            <input type="text" id="noVNC_host" placeholder="Host" value="localhost">
            <input type="text" id="noVNC_port" placeholder="Port" value="5900">
            <input type="password" id="noVNC_password" placeholder="Password (optional)">
        </div>
        <canvas id="noVNC_canvas"></canvas>
    </div>
    <script>
        // Initialize noVNC
        window.addEventListener('load', function() {
            var host = document.getElementById('noVNC_host').value;
            var port = document.getElementById('noVNC_port').value;
            var password = document.getElementById('noVNC_password').value;
            
            // Auto-connect
            setTimeout(function() {
                document.getElementById('noVNC_connect_button').click();
            }, 1000);
        });
    </script>
</body>
</html>
EOF2
fi

# Create health endpoint
echo "Creating health endpoint..."
mkdir -p /usr/share/novnc/health
echo "OK" > /usr/share/novnc/health/index.html

# Start noVNC directly on port 80 (NO nginx in between!)
echo "Starting noVNC on port 80..."
cd /usr/share/novnc
./utils/novnc_proxy --vnc localhost:5900 --listen 80 &

echo "=========================================="
echo "✅ Chrome RDP is READY!"
echo "🌐 Access at: http://localhost"
echo "🔗 Your Colab notebook is pre-loaded"
echo "=========================================="

# Keep container running
wait
