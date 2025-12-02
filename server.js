import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Enable Gzip compression
import compression from 'compression';
app.use(compression());

// Cache static files for 1 year
const staticOptions = {
    maxAge: '1y',
    etag: true,
    lastModified: true,
    setHeaders: (res, filepath) => {
        const fileExt = path.extname(filepath);
        if (fileExt === '.html') {
            res.setHeader('Cache-Control', 'public, max-age=0');
        } else if (fileExt === '.css' || fileExt === '.js') {
            res.setHeader('Cache-Control', 'public, max-age=31536000');
        }
    }
};

// Serve static files with caching
app.use(express.static(__dirname, staticOptions));

// Preload critical resources
app.use((req, res, next) => {
    if (req.url === '/') {
        res.setHeader('Link', '</style.css>; rel=preload; as=style, </script.js>; rel=preload; as=script');
    }
    next();
});

// Inline critical CSS for first paint
app.get('/', (req, res) => {
    const criticalCSS = `
        <style>
            *{margin:0;padding:0;box-sizing:border-box}
            body{font-family:system-ui,-apple-system,sans-serif;background:#0d1117;color:#fff;height:100vh;overflow:hidden}
            .browser-container{display:flex;flex-direction:column;height:100vh}
            .window-controls{background:#1a1a1a;padding:6px 12px;display:flex;align-items:center}
            .window-buttons{display:flex;gap:6px}
            .window-btn{width:12px;height:12px;border-radius:50%;border:none}
            .window-btn.close{background:#ff5f57}
            .window-btn.minimize{background:#ffbd2e}
            .window-btn.maximize{background:#28ca42}
            .browser-header{background:#161b22;padding:8px;display:flex;align-items:center;gap:8px;border-bottom:1px solid #30363d}
            .nav-controls{display:flex;gap:4px}
            .nav-btn{background:#21262d;border:none;color:#8b949e;width:32px;height:32px;border-radius:6px;cursor:pointer}
            .url-container{flex:1}
            .url-input-wrapper{background:#0d1117;border:1px solid #30363d;border-radius:20px;padding:6px 12px;display:flex;align-items:center}
            #url-bar{background:none;border:none;color:#fff;flex:1;font-size:14px;outline:none}
            .bookmarks-bar{background:#161b22;padding:4px;border-bottom:1px solid #30363d}
            .bookmarks-container{display:flex;gap:6px}
            .bookmark{background:#21262d;border:none;color:#c9d1d9;padding:4px 12px;border-radius:12px;font-size:12px;cursor:pointer}
            .tabs-container{background:#161b22;padding:0 8px;border-bottom:1px solid #30363d}
            .tab{background:#21262d;border:1px solid #30363d;border-radius:6px 6px 0 0;padding:6px 12px;margin-right:2px;cursor:pointer;min-width:120px}
            .tab.active{background:#0d1117;border-bottom:none}
            .main-content{flex:1;position:relative}
            .new-tab-page{position:absolute;top:0;left:0;right:0;bottom:0;background:linear-gradient(135deg,#0d1117 0%,#161b22 100%);display:flex;flex-direction:column;align-items:center;justify-content:center}
            .ntp-logo{text-align:center;margin-bottom:30px}
            .ntp-logo i{font-size:48px;color:#58a6ff}
            .ntp-search-box{background:#21262d;border:2px solid #30363d;border-radius:24px;padding:12px 20px;width:90%;max-width:600px;display:flex;align-items:center}
            #ntp-search{background:none;border:none;color:#fff;flex:1;font-size:16px;outline:none}
            .status-bar{background:#161b22;padding:6px 12px;display:flex;justify-content:space-between;font-size:11px;color:#8b949e}
            .webview-container{position:absolute;top:0;left:0;right:0;bottom:0}
            .webview{width:100%;height:100%;border:none;background:#fff}
            @media(max-width:768px){.browser-header{flex-wrap:wrap}.url-container{order:3;flex:100%;margin-top:8px}}
        </style>
    `;
    
    res.send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Chrome Browser</title>
            ${criticalCSS}
            <link rel="stylesheet" href="style.css" media="print" onload="this.media='all'">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
            <link rel="preconnect" href="https://fonts.googleapis.com">
            <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
            <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
            <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🌐</text></svg>">
            <noscript><link rel="stylesheet" href="style.css"></noscript>
        </head>
        <body>
            <div class="browser-container">
                <div class="window-controls">
                    <div class="window-buttons">
                        <button class="window-btn close"></button>
                        <button class="window-btn minimize"></button>
                        <button class="window-btn maximize"></button>
                    </div>
                </div>
                
                <div class="browser-header">
                    <div class="nav-controls">
                        <button class="nav-btn" title="Back"><i class="fas fa-arrow-left"></i></button>
                        <button class="nav-btn" title="Forward"><i class="fas fa-arrow-right"></i></button>
                        <button class="nav-btn" title="Reload"><i class="fas fa-redo"></i></button>
                    </div>
                    
                    <div class="url-container">
                        <div class="url-input-wrapper">
                            <i class="fas fa-search" style="color:#8b949e;margin-right:8px"></i>
                            <input type="text" id="url-bar" placeholder="Type URL or search..." autocomplete="off">
                        </div>
                    </div>
                </div>
                
                <div class="bookmarks-bar">
                    <div class="bookmarks-container">
                        <button class="bookmark">Google</button>
                        <button class="bookmark">YouTube</button>
                        <button class="bookmark">GitHub</button>
                        <button class="bookmark">Colab</button>
                    </div>
                </div>
                
                <div class="tabs-container">
                    <div class="tab active">New Tab</div>
                </div>
                
                <div class="main-content">
                    <div class="new-tab-page active">
                        <div class="ntp-logo">
                            <i class="fas fa-bolt"></i>
                            <h1 style="margin:10px 0;font-size:32px">Fast Browser</h1>
                            <p style="color:#8b949e">Loading...</p>
                        </div>
                        <div class="ntp-search-box">
                            <i class="fas fa-search" style="color:#8b949e;margin-right:12px"></i>
                            <input type="text" id="ntp-search" placeholder="Search or enter website address">
                        </div>
                    </div>
                    <div class="webview-container"></div>
                </div>
                
                <div class="status-bar">
                    <div>Ready</div>
                    <div>Fast Mode</div>
                </div>
            </div>
            
            <script>
                // Load remaining scripts after page is visible
                window.addEventListener('load', function() {
                    var script = document.createElement('script');
                    script.src = 'script.js';
                    script.async = true;
                    document.body.appendChild(script);
                    
                    // Show page immediately
                    document.querySelector('.ntp-logo p').textContent = 'Fast Chrome-like Browser';
                });
            </script>
        </body>
        </html>
    `);
});

// Health check
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

// Serve all other routes
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Start optimized server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Fast Browser running on port ${PORT}`);
    console.log(`⚡ Optimized for maximum speed`);
});
