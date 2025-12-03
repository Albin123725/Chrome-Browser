const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files from novnc directory
app.use(express.static('/usr/share/novnc'));

// Redirect root to VNC client
app.get('/', (req, res) => {
    res.redirect('/vnc_lite.html');
});

// Health check endpoint for Render
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

// Simple status page
app.get('/status', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Chrome RDP Status</title>
            <style>
                body { font-family: Arial; padding: 40px; background: #0d1117; color: white; text-align: center; }
                h1 { color: #58a6ff; }
                .status { background: #161b22; padding: 20px; border-radius: 10px; margin: 20px 0; }
                .btn { background: #238636; color: white; padding: 15px 30px; border: none; border-radius: 8px; cursor: pointer; margin: 10px; text-decoration: none; display: inline-block; }
                .info { background: rgba(255,165,0,0.1); padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FFA500; }
            </style>
        </head>
        <body>
            <div style="max-width: 600px; margin: 0 auto;">
                <h1>🌐 Chrome Cloud RDP</h1>
                <div class="status">
                    <h2 style="color: #2ea043;">✅ System Online</h2>
                    <p>VNC Server: Running</p>
                    <p>Chrome: Running with Colab</p>
                </div>
                <div class="info">
                    <strong>Your Colab Notebook:</strong><br>
                    https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1
                </div>
                <a href="/vnc_lite.html" class="btn">Connect to VNC</a>
                <a href="https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1" target="_blank" class="btn" style="background: #FFA500;">Open Colab Directly</a>
            </div>
        </body>
        </html>
    `);
});

app.listen(PORT, () => {
    console.log(`✅ Node.js server running on port ${PORT}`);
    console.log(`🌐 Health check: http://localhost:${PORT}/health`);
    console.log(`🔗 VNC Access: http://localhost:${PORT}/vnc_lite.html`);
});
