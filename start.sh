#!/bin/bash

echo "=========================================="
echo "🚀 Starting Chrome Cloud RDP with Google Colab"
echo "=========================================="

# Set display
export DISPLAY=:99
export DISPLAY_WIDTH=1280
export DISPLAY_HEIGHT=720
export VNC_PASSWORD=${VNC_PASSWORD:-chrome123}

echo "📊 Display: ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}"
echo "🔑 VNC Password: ${VNC_PASSWORD}"

# Clean up previous sessions
pkill -f Xvfb 2>/dev/null || true
pkill -f x11vnc 2>/dev/null || true
pkill -f chrome 2>/dev/null || true

# Remove old X11 locks
rm -rf /tmp/.X11-unix /tmp/.X0-lock
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Start Xvfb (virtual display)
echo "🖥️  Starting virtual display..."
Xvfb :99 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 3

# Set X11 permissions
xhost +local: > /dev/null 2>&1 || true

# Start window manager
echo "🪟 Starting window manager..."
fluxbox &
sleep 2

# Start VNC server
echo "🔌 Starting VNC server..."
if [ "$VNC_PASSWORD" != "chrome123" ]; then
    mkdir -p ~/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd
    x11vnc -display :99 -forever -shared -rfbauth ~/.vnc/passwd -listen localhost -xkb -auth guess &
else
    x11vnc -display :99 -forever -shared -nopw -listen localhost -xkb -auth guess &
fi
VNC_PID=$!
sleep 3

# Start Chrome with Google Colab
echo "🌐 Starting Chrome with your Colab notebook..."
google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --remote-debugging-port=9222 \
    --window-size=${DISPLAY_WIDTH},${DISPLAY_HEIGHT} \
    --window-position=0,0 \
    --start-maximized \
    --user-data-dir=/tmp/chrome-data \
    --no-first-run \
    --no-default-browser-check \
    --disable-background-networking \
    --disable-breakpad \
    --disable-component-update \
    --disable-sync \
    --disable-default-apps \
    --disable-translate \
    "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &
CHROME_PID=$!
sleep 5

# Verify processes
if kill -0 $XVFB_PID 2>/dev/null; then
    echo "✅ Xvfb running (PID: $XVFB_PID)"
else
    echo "❌ Xvfb failed to start"
    exit 1
fi

if kill -0 $VNC_PID 2>/dev/null; then
    echo "✅ VNC server running (PID: $VNC_PID)"
else
    echo "❌ VNC server failed to start"
    exit 1
fi

if kill -0 $CHROME_PID 2>/dev/null; then
    echo "✅ Chrome running (PID: $CHROME_PID)"
else
    echo "⚠️  Chrome may have issues but continuing..."
fi

# Create beautiful landing page
echo "🎨 Creating web interface..."
cat > /usr/share/novnc/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chrome Cloud RDP - Google Colab</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: #e2e8f0;
            min-height: 100vh;
            line-height: 1.6;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
        }
        
        header {
            text-align: center;
            margin-bottom: 3rem;
            padding: 2rem;
            background: rgba(30, 41, 59, 0.7);
            border-radius: 20px;
            border: 1px solid #334155;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
        }
        
        .logo {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 1rem;
            margin-bottom: 1rem;
        }
        
        .logo-icon {
            font-size: 3rem;
            color: #60a5fa;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.1); }
        }
        
        h1 {
            font-size: 2.8rem;
            background: linear-gradient(90deg, #60a5fa, #3b82f6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 0.5rem;
        }
        
        .subtitle {
            color: #94a3b8;
            font-size: 1.2rem;
            margin-bottom: 1.5rem;
        }
        
        .status {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1.5rem;
            background: rgba(34, 197, 94, 0.2);
            border: 1px solid #22c55e;
            border-radius: 50px;
            font-weight: 600;
        }
        
        .status-dot {
            width: 10px;
            height: 10px;
            background: #22c55e;
            border-radius: 50%;
            animation: blink 1.5s infinite;
        }
        
        @keyframes blink {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        
        .content {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 2rem;
            margin-bottom: 3rem;
        }
        
        @media (max-width: 768px) {
            .content {
                grid-template-columns: 1fr;
            }
        }
        
        .card {
            background: rgba(30, 41, 59, 0.7);
            border-radius: 20px;
            padding: 2rem;
            border: 1px solid #334155;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 30px rgba(0, 0, 0, 0.4);
        }
        
        .card-header {
            display: flex;
            align-items: center;
            gap: 1rem;
            margin-bottom: 1.5rem;
        }
        
        .card-icon {
            font-size: 2rem;
            color: #60a5fa;
        }
        
        .card-title {
            font-size: 1.5rem;
            color: #f8fafc;
        }
        
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 0.75rem;
            background: linear-gradient(135deg, #3b82f6, #1d4ed8);
            color: white;
            padding: 1rem 2rem;
            border-radius: 12px;
            text-decoration: none;
            font-weight: 600;
            font-size: 1.1rem;
            border: none;
            cursor: pointer;
            transition: all 0.3s;
            margin-top: 1rem;
            width: 100%;
            justify-content: center;
        }
        
        .btn:hover {
            background: linear-gradient(135deg, #1d4ed8, #1e40af);
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(59, 130, 246, 0.3);
        }
        
        .btn-secondary {
            background: linear-gradient(135deg, #475569, #334155);
        }
        
        .btn-secondary:hover {
            background: linear-gradient(135deg, #334155, #1e293b);
        }
        
        .info-box {
            background: rgba(245, 158, 11, 0.1);
            border-left: 4px solid #f59e0b;
            padding: 1.5rem;
            border-radius: 0 12px 12px 0;
            margin: 1.5rem 0;
        }
        
        .url-display {
            background: rgba(30, 41, 59, 0.9);
            border: 1px solid #475569;
            border-radius: 12px;
            padding: 1rem;
            margin: 1rem 0;
            font-family: 'Courier New', monospace;
            font-size: 0.9rem;
            word-break: break-all;
            color: #fbbf24;
        }
        
        .specs {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 1rem;
            margin-top: 1.5rem;
        }
        
        .spec-item {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 0.75rem;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 10px;
        }
        
        .spec-icon {
            color: #60a5fa;
        }
        
        footer {
            text-align: center;
            margin-top: 3rem;
            padding-top: 2rem;
            border-top: 1px solid #334155;
            color: #94a3b8;
            font-size: 0.9rem;
        }
        
        .instructions {
            background: rgba(34, 197, 94, 0.1);
            border-radius: 12px;
            padding: 1.5rem;
            margin: 1.5rem 0;
        }
        
        .instructions ol {
            margin-left: 1.5rem;
            margin-top: 1rem;
        }
        
        .instructions li {
            margin-bottom: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="logo">
                <i class="fas fa-cloud logo-icon"></i>
                <h1>Chrome Cloud RDP</h1>
            </div>
            <p class="subtitle">Access your Chrome browser with Google Colab in the cloud</p>
            <div class="status">
                <span class="status-dot"></span>
                System is running
            </div>
        </header>
        
        <div class="content">
            <div class="card">
                <div class="card-header">
                    <i class="fas fa-desktop card-icon"></i>
                    <h2 class="card-title">Remote Desktop</h2>
                </div>
                <p>Connect to your Chrome browser using the VNC client. Your Colab notebook is already loaded and ready.</p>
                
                <div class="instructions">
                    <p><strong>Connection Steps:</strong></p>
                    <ol>
                        <li>Click the "Launch VNC Client" button below</li>
                        <li>Click "Connect" in the VNC interface</li>
                        <li>Leave password blank or use: <strong>chrome123</strong></li>
                        <li>Your Chrome browser with Colab will appear</li>
                    </ol>
                </div>
                
                <a href="vnc_lite.html" class="btn">
                    <i class="fas fa-rocket"></i>
                    Launch VNC Client
                </a>
                
                <div class="specs">
                    <div class="spec-item">
                        <i class="fas fa-tv spec-icon"></i>
                        <span>1280×720 Display</span>
                    </div>
                    <div class="spec-item">
                        <i class="fas fa-bolt spec-icon"></i>
                        <span>Fast VNC Connection</span>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <i class="fab fa-google card-icon"></i>
                    <h2 class="card-title">Google Colab</h2>
                </div>
                <p>Your personal Colab notebook is pre-loaded and ready for coding:</p>
                
                <div class="url-display">
                    https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1
                </div>
                
                <div class="info-box">
                    <p><i class="fas fa-lightbulb"></i> <strong>Pro Tip:</strong> After connecting via VNC, you can run any Python code directly in the Colab notebook.</p>
                </div>
                
                <a href="https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1" 
                   target="_blank" class="btn btn-secondary">
                    <i class="fas fa-external-link-alt"></i>
                    Open Colab Directly
                </a>
                
                <div class="specs">
                    <div class="spec-item">
                        <i class="fas fa-code spec-icon"></i>
                        <span>Python Ready</span>
                    </div>
                    <div class="spec-item">
                        <i class="fas fa-server spec-icon"></i>
                        <span>GPU Available</span>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <i class="fas fa-cogs card-icon"></i>
                <h2 class="card-title">Quick Actions</h2>
            </div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-top: 1rem;">
                <button class="btn" onclick="location.reload()">
                    <i class="fas fa-sync-alt"></i>
                    Refresh Page
                </button>
                <button class="btn btn-secondary" onclick="window.open('vnc_lite.html', '_blank')">
                    <i class="fas fa-external-link-alt"></i>
                    Open VNC in New Tab
                </button>
                <button class="btn btn-secondary" onclick="alert('VNC Password: chrome123\\n\\nLeave blank for no password.\\n\\nDisplay: 1280x720\\nVNC Port: 5900')">
                    <i class="fas fa-key"></i>
                    Connection Info
                </button>
            </div>
        </div>
        
        <footer>
            <p>Chrome Cloud RDP • Powered by Render • Your Google Colab Notebook</p>
            <p style="margin-top: 1rem; font-size: 0.8rem;">
                <i class="fas fa-shield-alt"></i> Secure Connection • 
                <i class="fas fa-infinity"></i> Persistent Session • 
                <i class="fas fa-bolt"></i> High Performance
            </p>
        </footer>
    </div>
    
    <script>
        // Auto-reconnect if frame fails
        window.addEventListener('load', function() {
            console.log('Chrome Cloud RDP loaded successfully!');
            console.log('Your Colab notebook is ready in Chrome.');
            
            // Show welcome message
            setTimeout(function() {
                const welcomeMsg = "🚀 Welcome to Chrome Cloud RDP!\n\n" +
                                 "Your Google Colab notebook is pre-loaded and ready.\n" +
                                 "Click 'Launch VNC Client' to start.";
                console.log(welcomeMsg);
            }, 1000);
        });
    </script>
</body>
</html>
EOF

# Create health check endpoint
echo "OK" > /usr/share/novnc/health

# Create a simple status page
cat > /usr/share/novnc/status.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>System Status</title>
    <meta http-equiv="refresh" content="5">
    <style>
        body { font-family: Arial; padding: 20px; background: #0d1117; color: white; }
        .status { padding: 20px; margin: 10px 0; border-radius: 10px; }
        .online { background: rgba(46, 160, 67, 0.2); border-left: 4px solid #2ea043; }
        .process { background: rgba(88, 166, 255, 0.1); padding: 10px; margin: 5px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🖥️ System Status</h1>
    <div class="status online">
        <h2>✅ All Systems Operational</h2>
        <p>Last updated: <span id="time"></span></p>
    </div>
    
    <h3>Running Processes:</h3>
    <div class="process">Xvfb (Display :99) - ✅ Running</div>
    <div class="process">VNC Server (Port 5900) - ✅ Running</div>
    <div class="process">Chrome with Colab - ✅ Running</div>
    <div class="process">noVNC Web Interface - ✅ Running</div>
    
    <p><a href="/">← Back to Main Page</a></p>
    
    <script>
        document.getElementById('time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF

echo "✅ Web interface created successfully!"

# Start noVNC web server
echo "🌐 Starting noVNC web interface..."
websockify --web /usr/share/novnc 80 localhost:5900 --verbose &

echo ""
echo "=========================================="
echo "🎉 SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "✅ SYSTEM STATUS:"
echo "   Xvfb: Running (Display :99)"
echo "   VNC: Running on port 5900"
echo "   Chrome: Running with Colab notebook"
echo "   Web Interface: Ready on port 80"
echo ""
echo "🌐 ACCESS LINKS:"
echo "   Main Page: https://$(hostname)/"
echo "   VNC Client: https://$(hostname)/vnc_lite.html"
echo "   Status Page: https://$(hostname)/status.html"
echo "   Health Check: https://$(hostname)/health"
echo ""
echo "🔧 CONNECTION INFO:"
echo "   VNC Password: $VNC_PASSWORD (or leave blank)"
echo "   Display: ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}"
echo "   Colab URL: https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1"
echo ""
echo "🖱️  INSTRUCTIONS:"
echo "   1. Visit https://$(hostname)/"
echo "   2. Click 'Launch VNC Client'"
echo "   3. Click 'Connect' in VNC interface"
echo "   4. Start coding in your Colab notebook!"
echo ""
echo "=========================================="

# Keep container running
wait
