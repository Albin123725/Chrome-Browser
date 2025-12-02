class FastBrowser {
    constructor() {
        this.tabs = [];
        this.activeTabId = 1;
        this.history = [];
        this.zoomLevel = 100;
        
        // Initialize immediately
        this.initFast();
    }
    
    initFast() {
        // Get elements quickly
        this.urlBar = document.getElementById('url-bar');
        this.ntpSearch = document.getElementById('ntp-search');
        this.webviewContainer = document.querySelector('.webview-container');
        this.newTabPage = document.querySelector('.new-tab-page');
        this.statusBar = document.querySelector('.status-bar div:first-child');
        
        // Setup first tab immediately
        this.setupTab(1, 'New Tab', 'about:newtab');
        
        // Bind essential events only
        this.bindEssentialEvents();
        
        // Update UI
        this.updateStatus('Ready');
        
        // Load additional features after 1 second
        setTimeout(() => this.loadAdditionalFeatures(), 1000);
    }
    
    setupTab(id, title = 'New Tab', url = 'about:newtab') {
        const tab = { id, title, url, history: [] };
        this.tabs.push(tab);
        this.activeTabId = id;
    }
    
    bindEssentialEvents() {
        // URL bar navigation
        this.urlBar.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.navigateFast();
        });
        
        // NTP search
        this.ntpSearch.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.searchFromNTP();
        });
        
        // Bookmarks
        document.querySelectorAll('.bookmark').forEach(btn => {
            btn.addEventListener('click', () => {
                const text = btn.textContent;
                if (text === 'Google') this.navigateTo('https://www.google.com');
                else if (text === 'YouTube') this.navigateTo('https://www.youtube.com');
                else if (text === 'GitHub') this.navigateTo('https://github.com');
                else if (text === 'Colab') this.navigateTo('https://colab.research.google.com');
            });
        });
    }
    
    navigateFast() {
        const url = this.urlBar.value.trim();
        if (url) {
            this.navigateTo(url);
        }
    }
    
    searchFromNTP() {
        const query = this.ntpSearch.value.trim();
        if (query) {
            this.navigateTo(query);
        }
    }
    
    async navigateTo(url) {
        let finalUrl = url.trim();
        
        // Quick URL processing
        if (!finalUrl.startsWith('http')) {
            if (finalUrl.includes('.') && !finalUrl.includes(' ')) {
                finalUrl = 'https://' + finalUrl;
            } else if (finalUrl === 'mycolab') {
                finalUrl = 'https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing';
            } else {
                finalUrl = `https://www.google.com/search?q=${encodeURIComponent(finalUrl)}`;
            }
        }
        
        // Update UI immediately
        this.urlBar.value = finalUrl;
        this.showWebView(finalUrl);
        this.updateStatus(`Loading ${new URL(finalUrl).hostname}...`);
        
        // Hide NTP
        this.newTabPage.classList.remove('active');
        this.webviewContainer.style.display = 'block';
    }
    
    showWebView(url) {
        // Create iframe on demand
        let iframe = document.getElementById('webview');
        if (!iframe) {
            iframe = document.createElement('iframe');
            iframe.id = 'webview';
            iframe.className = 'webview';
            iframe.style.cssText = 'width:100%;height:100%;border:none;background:#fff';
            this.webviewContainer.appendChild(iframe);
        }
        
        // Load with proxy for speed
        const proxyUrl = `/api/proxy?url=${encodeURIComponent(url)}`;
        iframe.src = proxyUrl;
        
        // Update status when loaded
        iframe.onload = () => {
            this.updateStatus('Done');
            try {
                const title = iframe.contentDocument?.title || new URL(url).hostname;
                this.updateTabTitle(this.activeTabId, title);
            } catch (e) {
                this.updateTabTitle(this.activeTabId, new URL(url).hostname);
            }
        };
        
        iframe.onerror = () => {
            this.updateStatus('Failed to load');
            iframe.srcdoc = `
                <html><body style="background:#f5f5f5;display:flex;align-items:center;justify-content:center;height:100vh">
                    <div style="text-align:center">
                        <h2 style="color:#666">⚠️ Failed to load page</h2>
                        <p>Try visiting directly or check URL</p>
                        <a href="${url}" target="_blank" style="color:#4285f4">Open in new tab</a>
                    </div>
                </body></html>
            `;
        };
    }
    
    updateTabTitle(tabId, title) {
        const tab = this.tabs.find(t => t.id === tabId);
        if (tab) tab.title = title;
    }
    
    updateStatus(text) {
        if (this.statusBar) {
            this.statusBar.textContent = text;
        }
    }
    
    loadAdditionalFeatures() {
        // Load remaining features after page is visible
        this.setupFullNavigation();
        this.setupTabs();
        this.setupColabIntegration();
        this.setupQuickLinks();
    }
    
    setupFullNavigation() {
        const navButtons = document.querySelectorAll('.nav-btn');
        if (navButtons[0]) navButtons[0].addEventListener('click', () => this.goBack());
        if (navButtons[1]) navButtons[1].addEventListener('click', () => this.goForward());
        if (navButtons[2]) navButtons[2].addEventListener('click', () => this.reload());
    }
    
    setupTabs() {
        // Add new tab button
        const newTabBtn = document.createElement('button');
        newTabBtn.className = 'bookmark';
        newTabBtn.innerHTML = '<i class="fas fa-plus"></i> New Tab';
        newTabBtn.style.marginLeft = '8px';
        newTabBtn.addEventListener('click', () => this.createNewTab());
        document.querySelector('.tabs-container').appendChild(newTabBtn);
    }
    
    setupColabIntegration() {
        // Add Colab quick access
        const colabSection = document.createElement('div');
        colabSection.innerHTML = `
            <div style="margin-top:30px;text-align:center">
                <h3 style="color:#8b949e;margin-bottom:16px">Google Colab Quick Access</h3>
                <div style="display:flex;gap:8px;justify-content:center">
                    <button class="bookmark" data-colab="my">My Notebook</button>
                    <button class="bookmark" data-colab="new">New Notebook</button>
                    <button class="bookmark" data-colab="demo">Demo</button>
                </div>
                <p style="color:#6e7681;margin-top:12px;font-size:12px">Type "mycolab" in address bar</p>
            </div>
        `;
        document.querySelector('.new-tab-page').appendChild(colabSection);
        
        // Add Colab event listeners
        document.querySelectorAll('[data-colab]').forEach(btn => {
            btn.addEventListener('click', () => {
                const type = btn.dataset.colab;
                if (type === 'my') {
                    this.navigateTo('https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing');
                } else if (type === 'new') {
                    this.navigateTo('https://colab.new');
                } else if (type === 'demo') {
                    this.navigateTo('https://colab.research.google.com/github/googlecolab/colabtools/blob/master/notebooks/colab-github-demo.ipynb');
                }
            });
        });
    }
    
    setupQuickLinks() {
        const links = [
            { name: 'Google', url: 'https://google.com', icon: 'fab fa-google' },
            { name: 'YouTube', url: 'https://youtube.com', icon: 'fab fa-youtube' },
            { name: 'GitHub', url: 'https://github.com', icon: 'fab fa-github' },
            { name: 'ChatGPT', url: 'https://chat.openai.com', icon: 'fas fa-robot' },
            { name: 'Wikipedia', url: 'https://wikipedia.org', icon: 'fab fa-wikipedia-w' },
            { name: 'Colab', url: 'https://colab.research.google.com', icon: 'fab fa-google', color: '#FFA500' }
        ];
        
        const grid = document.querySelector('.quick-links-grid');
        if (grid) {
            grid.innerHTML = links.map(link => `
                <div class="quick-link-card" data-url="${link.url}">
                    <div class="quick-link-icon" style="${link.color ? `background:${link.color}` : ''}">
                        <i class="${link.icon}"></i>
                    </div>
                    <span class="quick-link-title">${link.name}</span>
                </div>
            `).join('');
            
            grid.querySelectorAll('.quick-link-card').forEach(card => {
                card.addEventListener('click', () => {
                    const url = card.dataset.url;
                    this.navigateTo(url);
                });
            });
        }
    }
    
    createNewTab() {
        const newId = this.tabs.length + 1;
        this.setupTab(newId);
        this.activeTabId = newId;
        this.showNewTabPage();
        this.updateStatus('New Tab');
    }
    
    showNewTabPage() {
        this.newTabPage.classList.add('active');
        this.webviewContainer.style.display = 'none';
        this.urlBar.value = '';
        this.ntpSearch.focus();
    }
    
    goBack() {
        const tab = this.tabs.find(t => t.id === this.activeTabId);
        if (tab && tab.history.length > 1) {
            tab.history.pop();
            const prevUrl = tab.history[tab.history.length - 1];
            if (prevUrl) {
                this.navigateTo(prevUrl);
            }
        }
    }
    
    goForward() {
        // Simplified - would need proper history tracking
        this.updateStatus('Forward not implemented in fast mode');
    }
    
    reload() {
        const iframe = document.getElementById('webview');
        if (iframe && iframe.src) {
            iframe.src = iframe.src;
            this.updateStatus('Reloading...');
        }
    }
}

// Start browser immediately when page loads
window.addEventListener('DOMContentLoaded', () => {
    // Show browser is loading
    document.querySelector('.ntp-logo p').textContent = 'Starting...';
    
    // Initialize fast browser
    window.browser = new FastBrowser();
    
    // Update UI
    setTimeout(() => {
        document.querySelector('.ntp-logo h1').textContent = 'Fast Browser';
        document.querySelector('.ntp-subtitle').textContent = 'Loaded in under 1 second';
        document.querySelector('.ntp-search').placeholder = 'Try: google.com or "mycolab"';
    }, 300);
});

// Add error handling
window.addEventListener('error', (e) => {
    console.error('Browser error:', e.error);
});

// Add offline detection
window.addEventListener('offline', () => {
    alert('You are offline. Some features may not work.');
});
