#!/bin/bash

echo "🚀 Starting Chrome RDP with Google Colab..."

# Clean up
rm -rf /tmp/.X11-unix /tmp/.X*-lock
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Set display
export DISPLAY=:99

# Start Xvfb
echo "Starting virtual display..."
Xvfb :99 -screen 0 1280x720x24 -ac &
sleep 2

# Set up Xauth
touch /root/.Xauthority
xauth generate :99 . trusted

# Start fluxbox
echo "Starting window manager..."
fluxbox &
sleep 1

# Start VNC
echo "Starting VNC server..."
x11vnc -display :99 -forever -shared -nopw -listen localhost -auth /root/.Xauthority &
sleep 2

# Start Chrome
echo "Starting Chrome with Colab..."
google-chrome-stable --no-sandbox --disable-dev-shm-usage \
    --window-size=1280,720 \
    "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &
sleep 5

echo "✅ Chrome started with Colab"

# Create web interface files
echo "Creating web interface..."
mkdir -p /opt/noVNC

# Create index.html
cat > /opt/noVNC/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Chrome Cloud RDP</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
            transform: translateY(-2px);
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
        .info-box {
            background: rgba(255,165,0,0.1);
            border-left: 4px solid #FFA500;
            padding: 15px;
            border-radius: 0 8px 8px 0;
            margin: 20px 0;
            text-align: left;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Chrome Cloud RDP</h1>
        <p>Your browser with Google Colab is ready!</p>
        
        <div class="loader"></div>
        
        <p>Connecting to your Chrome instance...</p>
        
        <a href="/vnc_lite.html" class="btn">🚀 Launch VNC Client</a>
        <a href="https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1" 
           target="_blank" class="btn" style="background: #FFA500;">
           📒 Open Colab Directly
        </a>
        
        <div class="info-box">
            <p><strong>Instructions:</strong></p>
            <ol style="text-align: left; margin-left: 20px;">
                <li>Click "Launch VNC Client"</li>
                <li>Click "Connect" in the VNC interface</li>
                <li>Leave password blank (no password needed)</li>
                <li>Your Colab notebook will be open in Chrome</li>
            </ol>
        </div>
        
        <div style="margin-top: 30px; padding: 15px; background: rgba(88,166,255,0.1); border-radius: 8px;">
            <p><strong>Connection Status:</strong> ✅ All systems running</p>
            <p><strong>VNC Server:</strong> localhost:5900</p>
            <p><strong>Display:</strong> 1280x720</p>
        </div>
    </div>
    
    <script>
        // Auto-redirect after 3 seconds
        setTimeout(function() {
            window.location.href = '/vnc_lite.html';
        }, 3000);
    </script>
</body>
</html>
EOF

# Copy noVNC files if they exist in /usr/share/novnc
if [ -d "/usr/share/novnc" ]; then
    echo "Copying noVNC files..."
    cp -r /usr/share/novnc/* /opt/noVNC/ 2>/dev/null || true
fi

# Create vnc_lite.html if missing
if [ ! -f "/opt/noVNC/vnc_lite.html" ]; then
    echo "Creating VNC client page..."
    cat > /opt/noVNC/vnc_lite.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>noVNC</title>
    <meta charset="UTF-8">
    <script type="module">
        import RFB from './core/rfb.js';
        
        document.addEventListener('DOMContentLoaded', function() {
            const host = window.location.hostname;
            const port = 80;
            const password = '';
            const path = 'websockify';
            
            const rfb = new RFB(document.getElementById('noVNC_canvas'), 
                `ws://${host}:${port}/${path}`, {
                    credentials: { password: password }
                });
            
            rfb.addEventListener("connect", function() {
                console.log("Connected to VNC server");
                document.getElementById('status').textContent = '✅ Connected';
            });
            
            rfb.addEventListener("disconnect", function() {
                console.log("Disconnected from VNC server");
                document.getElementById('status').textContent = '❌ Disconnected';
            });
        });
    </script>
    <style>
        body { margin: 0; padding: 20px; background: #1a1a1a; color: white; }
        #noVNC_canvas { width: 100%; height: 80vh; border: 2px solid #4285f4; }
        .controls { margin: 20px 0; }
        button { background: #4285f4; color: white; padding: 10px 20px; border: none; margin: 5px; }
    </style>
</head>
<body>
    <h1>VNC Client</h1>
    <p>Status: <span id="status">Connecting...</span></p>
    <div class="controls">
        <button onclick="location.reload()">Reconnect</button>
        <button onclick="window.location.href='/'">Back to Home</button>
    </div>
    <canvas id="noVNC_canvas"></canvas>
</body>
</html>
EOF
fi

# Create health endpoint
echo "OK" > /opt/noVNC/health

# Create simple status
cat > /opt/noVNC/status.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Status</title></head>
<body>✅ System is running</body>
</html>
EOF

echo "Web interface created at /opt/noVNC"

# Start noVNC
echo "Starting noVNC web interface..."
cd /opt/noVNC

# Use python websockify directly
python3 -m websockify --web /opt/noVNC 80 localhost:5900 &

echo ""
echo "=========================================="
echo "✅ SYSTEM READY!"
echo "=========================================="
echo ""
echo "🌐 Access your Chrome RDP at:"
echo "   Main Page: http://$(hostname)/"
echo "   VNC Client: http://$(hostname)/vnc_lite.html"
echo "   Status: http://$(hostname)/status.html"
echo "   Health: http://$(hostname)/health"
echo ""
echo "🔧 Connection Info:"
echo "   VNC Server: localhost:5900"
echo "   Password: none (leave blank)"
echo "   Display: 1280x720"
echo ""
echo "📒 Your Colab notebook is pre-loaded in Chrome"
echo "=========================================="

# Keep running
wait
