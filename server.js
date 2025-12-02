import express from 'express';
import path from 'path';
import fetch from 'node-fetch';
import { fileURLToPath } from 'url';

// Get __dirname in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.static(__dirname));
app.use(express.json());

// Fix Colab iframe issues
function fixColabContent(html) {
    // Remove X-Frame-Options and Content-Security-Policy headers from HTML
    html = html.replace(/<meta[^>]*(?:X-Frame-Options|Content-Security-Policy)[^>]*>/gi, '');
    
    // Allow iframe embedding
    html = html.replace(/<head>/i, '<head><meta name="referrer" content="no-referrer">');
    
    // Fix relative URLs
    html = html.replace(/(src|href)=["'](?!https?:\/\/)(?!data:)(?!\/\/)([^"']+)["']/gi, 
        (match, attr, value) => `${attr}="https://colab.research.google.com${value.startsWith('/') ? '' : '/'}${value}"`);
    
    return html;
}

// Proxy endpoint for bypassing CORS
app.get('/api/proxy', async (req, res) => {
    const url = decodeURIComponent(req.query.url);
    
    if (!url) {
        return res.status(400).json({ error: 'URL parameter is required' });
    }

    try {
        console.log(`Proxy request for: ${url}`);
        
        // Special headers for Colab
        const headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-User': '?1',
            'Cache-Control': 'max-age=0'
        };
        
        // Add Colab-specific headers
        if (url.includes('colab.research.google.com')) {
            headers['Origin'] = 'https://colab.research.google.com';
            headers['Referer'] = 'https://colab.research.google.com/';
            headers['Sec-Fetch-Site'] = 'same-origin';
        }

        const response = await fetch(url, {
            headers: headers,
            timeout: 15000 // Longer timeout for Colab
        });

        const contentType = response.headers.get('content-type') || 'text/html';
        let html = await response.text();
        
        // Fix Colab iframe issues
        if (url.includes('colab.research.google.com')) {
            html = fixColabContent(html);
        }
        
        res.set('Content-Type', contentType);
        res.set('X-Frame-Options', 'ALLOW-FROM https://chrome-browser-4ct2.onrender.com');
        res.set('Access-Control-Allow-Origin', '*');
        res.send(html);
        
    } catch (error) {
        console.error('Proxy error:', error.message);
        
        // Return error page
        const errorPage = `
            <!DOCTYPE html>
            <html>
            <head>
                <title>Error Loading Page</title>
                <style>
                    body {
                        font-family: Arial, sans-serif;
                        padding: 40px;
                        text-align: center;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        min-height: 100vh;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                    }
                    .error-container {
                        background: rgba(255, 255, 255, 0.1);
                        backdrop-filter: blur(10px);
                        padding: 40px;
                        border-radius: 20px;
                        max-width: 600px;
                        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
                    }
                    h1 {
                        font-size: 48px;
                        margin-bottom: 20px;
                    }
                    p {
                        font-size: 18px;
                        margin-bottom: 30px;
                        opacity: 0.9;
                    }
                    .btn {
                        background: white;
                        color: #667eea;
                        padding: 12px 30px;
                        border-radius: 50px;
                        text-decoration: none;
                        font-weight: bold;
                        display: inline-block;
                        transition: transform 0.3s;
                    }
                    .btn:hover {
                        transform: translateY(-2px);
                    }
                </style>
            </head>
            <body>
                <div class="error-container">
                    <h1>🚫</h1>
                    <h1>Unable to Load Page</h1>
                    <p>${error.message || 'The website might be blocking proxy requests or is temporarily unavailable.'}</p>
                    <p>Try visiting the site directly or check if the URL is correct.</p>
                    <a href="/" class="btn">Return to Browser</a>
                </div>
            </body>
            </html>
        `;
        
        res.status(500).send(errorPage);
    }
});

// API endpoint for search suggestions
app.get('/api/search', async (req, res) => {
    const query = req.query.q;
    
    if (!query) {
        return res.json({ suggestions: [] });
    }
    
    try {
        const response = await fetch(
            `https://suggestqueries.google.com/complete/search?client=firefox&q=${encodeURIComponent(query)}`
        );
        const data = await response.json();
        res.json({ suggestions: data[1] || [] });
    } catch (error) {
        res.json({ suggestions: [] });
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'web-browser',
        version: '1.0.0'
    });
});

// Serve main HTML file
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Serve all other routes with index.html (for SPA)
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Start server
app.listen(PORT, () => {
    console.log(`
    🚀 Web Browser App is running!
    🌐 URL: https://chrome-browser-4ct2.onrender.com
    📁 Files served from: ${__dirname}
    🔧 Proxy server active
    💾 Google Colab integration enabled
    `);
});
// Add specific MIME types
app.use(express.static(__dirname, {
    setHeaders: (res, path) => {
        if (path.endsWith('.css')) {
            res.set('Content-Type', 'text/css');
        }
        if (path.endsWith('.js')) {
            res.set('Content-Type', 'application/javascript');
        }
    }
}));
