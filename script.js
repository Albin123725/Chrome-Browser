class WebBrowser {
    constructor() {
        this.tabs = [];
        this.activeTabId = 1;
        this.history = [];
        this.bookmarks = [];
        this.zoomLevel = 100;
        this.currentUrl = '';
        this.useProxy = true; // Enable proxy for cross-origin requests
        
        this.initElements();
        this.bindEvents();
        this.loadBookmarks();
        this.setupTab(1, 'New Tab', 'about:newtab');
        this.updateUI();
        
        // Check if we're on Render
        this.isRender = window.location.hostname.includes('render.com') || 
                       window.location.hostname.includes('onrender.com');
    }
    
    // ... [Previous code remains the same until the navigateTo method] ...
    
    async navigateTo(url) {
        let finalUrl = url.trim();
        
        // Add protocol if missing
        if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
            if (finalUrl.includes('.')) {
                finalUrl = 'https://' + finalUrl;
            } else {
                // It's a search query
                finalUrl = `https://www.google.com/search?q=${encodeURIComponent(finalUrl)}`;
            }
        }
        
        const activeTab = this.getActiveTab();
        
        // Add to history
        if (activeTab.historyIndex >= 0) {
            // Remove forward history
            activeTab.history = activeTab.history.slice(0, activeTab.historyIndex + 1);
        }
        activeTab.history.push(finalUrl);
        activeTab.historyIndex = activeTab.history.length - 1;
        
        // Update tab
        activeTab.url = finalUrl;
        this.updateTabTitle(activeTab.id, new URL(finalUrl).hostname);
        
        // Update URL bar
        this.urlBar.value = finalUrl;
        
        // Navigate using proxy if needed
        await this.showWebView(finalUrl);
        this.updateSecurityIcon(finalUrl);
        this.updateNavigationButtons();
    }
    
    async showWebView(url) {
        this.newTabPage.classList.remove('active');
        this.webview.style.display = 'block';
        
        // Update status
        this.statusText.textContent = `Loading ${url}...`;
        
        // Load the URL using proxy if cross-origin
        try {
            if (this.isRender && this.useProxy) {
                // Use proxy for cross-origin requests
                const proxyUrl = `/api/proxy?url=${encodeURIComponent(url)}`;
                
                // Create a blob URL for the content
                const response = await fetch(proxyUrl);
                const contentType = response.headers.get('content-type');
                const content = await response.text();
                
                // Create a blob and load it in iframe
                const blob = new Blob([content], { type: contentType });
                const blobUrl = URL.createObjectURL(blob);
                this.webview.src = blobUrl;
            } else {
                // Direct load (may be blocked by CORS)
                this.webview.src = url;
            }
        } catch (error) {
            console.error('Error loading page:', error);
            this.showErrorPage(`Failed to load: ${url}`);
        }
    }
    
    showErrorPage(message) {
        const errorHTML = `
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {
                        font-family: Arial, sans-serif;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        height: 100vh;
                        background: #f5f5f5;
                        color: #333;
                    }
                    .error-container {
                        text-align: center;
                        padding: 40px;
                        background: white;
                        border-radius: 10px;
                        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                    }
                    .error-icon {
                        font-size: 48px;
                        color: #ea4335;
                        margin-bottom: 20px;
                    }
                    h1 {
                        color: #ea4335;
                        margin-bottom: 10px;
                    }
                    p {
                        margin-bottom: 20px;
                        color: #666;
                    }
                    button {
                        background: #4285f4;
                        color: white;
                        border: none;
                        padding: 10px 20px;
                        border-radius: 5px;
                        cursor: pointer;
                        font-size: 16px;
                    }
                    button:hover {
                        background: #3367d6;
                    }
                </style>
            </head>
            <body>
                <div class="error-container">
                    <div class="error-icon">⚠️</div>
                    <h1>Failed to Load Page</h1>
                    <p>${message}</p>
                    <p>Some websites block being loaded in iframes for security reasons.</p>
                    <button onclick="window.location.href = '/'">Go Back</button>
                </div>
            </body>
            </html>
        `;
        
        const blob = new Blob([errorHTML], { type: 'text/html' });
        const blobUrl = URL.createObjectURL(blob);
        this.webview.src = blobUrl;
        this.statusText.textContent = 'Error loading page';
    }
    
    // ... [Rest of the code remains the same] ...
}

// Initialize the browser when the page loads
window.addEventListener('DOMContentLoaded', () => {
    const browser = new WebBrowser();
    window.browser = browser;
});
