import { createServer } from 'http';
import { readFile } from 'fs/promises';
import { join, extname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = join(fileURLToPath(import.meta.url), '..');

const PORT = process.env.PORT || 3000;

// MIME types
const mimeTypes = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

const server = createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host}`);
    let filePath = url.pathname === '/' ? '/index.html' : url.pathname;
    
    // Security: prevent directory traversal
    if (filePath.includes('..')) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }
    
    // Health check
    if (filePath === '/health') {
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('OK');
      return;
    }
    
    // Proxy endpoint
    if (filePath.startsWith('/api/proxy')) {
      const targetUrl = url.searchParams.get('url');
      if (targetUrl) {
        try {
          const proxyRes = await fetch(targetUrl);
          const data = await proxyRes.text();
          const contentType = proxyRes.headers.get('content-type') || 'text/html';
          
          res.writeHead(200, {
            'Content-Type': contentType,
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'no-cache'
          });
          res.end(data);
        } catch (error) {
          res.writeHead(500);
          res.end('Proxy error');
        }
      } else {
        res.writeHead(400);
        res.end('Missing URL parameter');
      }
      return;
    }
    
    // Normal file serving
    const fullPath = join(__dirname, filePath);
    const ext = extname(filePath);
    const contentType = mimeTypes[ext] || 'text/plain';
    
    // Read and serve file
    const data = await readFile(fullPath, 'utf8');
    
    // Set cache headers for static files
    const cacheControl = ext === '.html' 
      ? 'public, max-age=0' 
      : 'public, max-age=31536000';
    
    res.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': cacheControl,
      'X-Powered-By': 'FastBrowser/1.0'
    });
    
    res.end(data);
    
  } catch (error) {
    if (error.code === 'ENOENT') {
      // File not found - serve index.html for SPA
      try {
        const data = await readFile(join(__dirname, 'index.html'), 'utf8');
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(data);
      } catch {
        res.writeHead(404);
        res.end('File not found');
      }
    } else {
      console.error('Server error:', error);
      res.writeHead(500);
      res.end('Internal server error');
    }
  }
});

server.listen(PORT, () => {
  console.log(`
  ⚡ Fast Browser Server
  🌐 Port: ${PORT}
  🚀 Zero dependencies
  📁 Serving from: ${__dirname}
  `);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('Shutting down...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
