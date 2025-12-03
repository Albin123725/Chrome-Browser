#!/bin/bash

echo "=========================================="
echo "Starting Chrome RDP - Direct noVNC on port 80"
echo "=========================================="

# Set display
export DISPLAY=:99
export DISPLAY_WIDTH=1280
export DISPLAY_HEIGHT=720

# Kill any existing processes
pkill -f Xvfb 2>/dev/null || true
pkill -f x11vnc 2>/dev/null || true
pkill -f websockify 2>/dev/null || true

# Start X virtual framebuffer
Xvfb :99 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x24 -ac +extension GLX +render -noreset &
sleep 2

# Start window manager
fluxbox &
sleep 1

# Start VNC server
x11vnc -display :99 -forever -shared -nopw -listen localhost -xkb &
sleep 2

# Start Chrome with your Colab notebook
echo "Starting Chrome with your Colab notebook..."
google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --window-size=${DISPLAY_WIDTH},${DISPLAY_HEIGHT} \
    --start-maximized \
    --user-data-dir=/tmp/chrome \
    --no-first-run \
    --no-default-browser-check \
    "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &
sleep 5

# Create custom HTML page for noVNC
echo "Creating custom VNC interface..."
mkdir -p /usr/share/novnc
cat > /usr/share/novnc/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Chrome Cloud RDP - Your Google Colab</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0d1117 0%, #161b22 100%);
            color: #c9d1d9;
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 15px;
            border: 1px solid #30363d;
        }
        h1 {
            color: #58a6ff;
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #8b949e;
            font-size: 1.1rem;
        }
        .content {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin-bottom: 30px;
        }
        @media (max-width: 768px) {
            .content {
                grid-template-columns: 1fr;
            }
        }
        .panel {
            background: rgba(255, 255, 255, 0.05);
            border-radius: 15px;
            padding: 25px;
            border: 1px solid #30363d;
        }
        .panel h2 {
            color: #58a6ff;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .panel h2 i {
            font-size: 1.5rem;
        }
        .vnc-frame {
            width: 100%;
            height: 600px;
            border: none;
            border-radius: 10px;
            background: #000;
        }
        .info-box {
            background: rgba(88, 166, 255, 0.1);
            border-left: 4px solid #58a6ff;
            padding: 15px;
            margin: 15px 0;
            border-radius: 0 8px 8px 0;
        }
        .btn {
            background: #238636;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            margin: 5px;
        }
        .btn:hover {
            background: #2ea043;
            transform: translateY(-2px);
        }
        .btn-secondary {
            background: #30363d;
        }
        .btn-secondary:hover {
            background: #484f58;
        }
        .colab-url {
            background: rgba(255, 165, 0, 0.1);
            border: 1px solid #FFA500;
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
