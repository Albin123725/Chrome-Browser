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
    --window-size=1280,720 --start-maximized \
    "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &

# Create an index.html that redirects to VNC
cat > /usr/share/novnc/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Chrome Cloud RDP - Your Google Colab</title>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0; url=vnc_lite.html">
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #0d1117 0%, #161b22 100%);
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
            max-width: 600px;
            padding: 40px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 15px;
            border: 1px solid #30363d;
        }
        h1 {
            color: #58a6ff;
            margin-bottom: 20px;
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
        <p>If not redirected automatically, click below:</p>
        
        <a href="vnc_lite.html" class="btn">🚀 Launch VNC Client</a>
        
        <div style="margin-top: 30px; padding: 15px; background: rgba(255,165,0,0.1); border-radius: 8px; border-left: 4px solid #FFA500;">
            <strong>Your Colab Notebook:</strong><br>
            <small>https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1</small>
        </div>
    </div>
</body>
</html>
EOF

# Also create a simple health check
echo "OK" > /usr/share/novnc/health

# Start noVNC
echo "Starting noVNC web interface..."
websockify --web /usr/share/novnc 80 localhost:5900

echo "✅ Ready! Access at: http://localhost"
