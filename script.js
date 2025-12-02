class WebBrowser {
    constructor() {
        this.tabs = [];
        this.activeTabId = 1;
        this.history = [];
        this.bookmarks = [];
        this.zoomLevel = 100;
        this.currentUrl = '';
        this.useProxy = true;
        this.theme = 'dark';
        this.settings = {};
        
        this.initElements();
        this.bindEvents();
        this.loadSettings();
        this.loadBookmarks();
        this.setupTab(1, 'New Tab', 'about:newtab');
        this.applyTheme();
        this.updateUI();
        
        // Check if we're on Render
        this.isRender = window.location.hostname.includes('render.com') || 
                       window.location.hostname.includes('onrender.com');
    }
    
    initElements() {
        // Navigation elements
        this.urlBar = document.getElementById('url-bar');
        this.btnBack = document.getElementById('btn-back');
        this.btnForward = document.getElementById('btn-forward');
        this.btnReload = document.getElementById('btn-reload');
        this.btnHome = document.getElementById('btn-home');
        this.btnClear = document.getElementById('btn-clear');
        this.btnFavorite = document.getElementById('btn-favorite');
        this.securityIcon = document.getElementById('security-icon');
        
        // Tab elements
        this.tabsList = document.getElementById('tabs-list');
        this.btnNewTab = document.getElementById('btn-new-tab');
        
        // WebView elements
        this.webview = document.getElementById('webview');
        this.newTabPage = document.getElementById('new-tab-page');
        this.webviewContainer = document.getElementById('webview-container');
        this.webviewOverlay = document.getElementById('webview-overlay');
        
        // New Tab Page elements
        this.ntpSearch = document.getElementById('ntp-search');
        this.ntpSearchBtn = document.getElementById('ntp-search-btn');
        this.recentSites = document.getElementById('recent-sites');
        
        // Status elements
        this.statusText = document.getElementById('status-text');
        this.pageInfo = document.getElementById('page-info');
        this.zoomLevelDisplay = document.getElementById('zoom-level');
        this.btnZoomIn = document.getElementById('btn-zoom-in');
        this.btnZoomOut = document.getElementById('btn-zoom-out');
        this.btnZoomReset = document.getElementById('btn-zoom-reset');
        this.btnFullscreen = document.getElementById('btn-fullscreen');
        
        // Modal elements
        this.modalOverlay = document.getElementById('modal-overlay');
        this.bookmarksModal = document.getElementById('bookmarks-modal');
        this.settingsModal = document.getElementById('settings-modal');
        this.btnSettings = document.getElementById('btn-settings');
        this.btnMenu = document.getElementById('btn-menu');
        
        // Search suggestions
        this.searchSuggestions = document.getElementById('search-suggestions');
        
        // Window elements
        this.windowTitle = document.getElementById('window-title-text');
        
        // Toast
        this.toast = document.getElementById('toast');
    }
    
    bindEvents() {
        // Navigation
        this.btnBack.addEventListener('click', () => this.goBack());
        this.btnForward.addEventListener('click', () => this.goForward());
        this.btnReload.addEventListener('click', () => this.reload());
        this.btnHome.addEventListener('click', () => this.goHome());
        this.btnClear.addEventListener('click', () => this.clearUrlBar());
        this.btnFavorite.addEventListener('click', () => this.toggleBookmark());
        this.urlBar.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.navigate();
        });
        this.urlBar.addEventListener('input', (e) => this.handleSearchInput(e.target.value));
        
        // Tabs
        this.btnNewTab.addEventListener('click', () => this.createNewTab());
        
        // New Tab Page
        this.ntpSearch.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.searchFromNTP();
        });
        this.ntpSearchBtn.addEventListener('click', () => this.searchFromNTP());
        
        // Quick links
        document.querySelectorAll('.quick-link-card').forEach(link => {
            link.addEventListener('click', () => {
                const url = link.dataset.url;
                this.navigateTo(url);
            });
        });
        
        // Bookmarks bar
        document.querySelectorAll('.bookmark[data-url]').forEach(bookmark => {
            bookmark.addEventListener('click', () => {
                const url = bookmark.dataset.url;
                this.navigateTo(url);
            });
        });
        
        // Add bookmark button
        document.getElementById('btn-add-bookmark').addEventListener('click', () => {
            this.showBookmarksModal();
        });
        
        // Zoom controls
        this.btnZoomIn.addEventListener('click', () => this.zoomIn());
        this.btnZoomOut.addEventListener('click', () => this.zoomOut());
        this.btnZoomReset.addEventListener('click', () => this.zoomReset());
        this.btnFullscreen.addEventListener('click', () => this.toggleFullscreen());
        
        // Settings
        this.btnSettings.addEventListener('click', () => this.showSettingsModal());
        this.btnMenu.addEventListener('click', () => this.showMenu());
        
        // Settings modal events
        document.querySelectorAll('.settings-tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                const tabName = e.target.dataset.tab;
                this.switchSettingsTab(tabName);
            });
        });
        
        document.querySelectorAll('.theme-option').forEach(option => {
            option.addEventListener('click', (e) => {
                const theme = e.currentTarget.dataset.theme;
                this.setTheme(theme);
            });
        });
        
        document.getElementById('zoom-slider').addEventListener('input', (e) => {
            this.zoomLevel = parseInt(e.target.value);
            this.updateZoom();
        });
        
        document.getElementById('btn-save-settings').addEventListener('click', () => {
            this.saveSettings();
            this.closeModals();
            this.showToast('Settings saved successfully', 'success');
        });
        
        // Close modals
        document.querySelectorAll('.modal-close').forEach(btn => {
            btn.addEventListener('click', () => this.closeModals());
        });
        this.modalOverlay.addEventListener('click', () => this.closeModals());
        
        // Window controls
        document.querySelectorAll('.window-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                this.showToast('Window controls are simulated in this web version', 'info');
            });
        });
        
        // WebView events
        this.webview.addEventListener('load', () => this.onPageLoad());
        this.webview.addEventListener('error', () => this.onPageError());
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => this.handleKeyboardShortcuts(e));
        
        // Update window title when tab changes
        this.updateWindowTitle();
    }
    
    setupTab(id, title = 'New Tab', url = 'about:newtab') {
        const tab = {
            id,
            title,
            url,
            history: [],
            historyIndex: -1,
            favicon: 'fas fa-globe',
            isLoading: false
        };
        
        this.tabs.push(tab);
        this.activeTabId = id;
        
        // Create tab element
        const tabElement = document.createElement('div');
        tabElement.className = 'tab';
        tabElement.dataset.tabId = id;
        tabElement.innerHTML = `
            <div class="tab-content">
                <i class="fas fa-globe tab-icon"></i>
                <span class="tab-title">${title}</span>
            </div>
            <button class="tab-close">
                <i class="fas fa-times"></i>
            </button>
        `;
        
        // Insert before new tab button
        this.tabsList.appendChild(tabElement);
        
        // Add event listeners
        tabElement.addEventListener('click', (e) => {
            if (!e.target.closest('.tab-close')) {
                this.switchTab(id);
            }
        });
        
        tabElement.querySelector('.tab-close').addEventListener('click', (e) => {
            e.stopPropagation();
            this.closeTab(id);
        });
        
        return tab;
    }
    
    getActiveTab() {
        return this.tabs.find(tab => tab.id === this.activeTabId);
    }
    
    switchTab(tabId) {
        // Update active tab
        this.activeTabId = tabId;
        
        // Update tab UI
        document.querySelectorAll('.tab').forEach(tab => {
            tab.classList.remove('active');
            if (parseInt(tab.dataset.tabId) === tabId) {
                tab.classList.add('active');
            }
        });
        
        const activeTab = this.getActiveTab();
        
        // Update URL bar
        this.urlBar.value = activeTab.url !== 'about:newtab' ? activeTab.url : '';
        
        // Update security icon
        this.updateSecurityIcon(activeTab.url);
        
        // Show appropriate content
        if (activeTab.url === 'about:newtab') {
            this.showNewTabPage();
        } else {
            this.showWebView(activeTab.url);
        }
        
        // Update navigation buttons
        this.updateNavigationButtons();
        
        // Update window title
        this.updateWindowTitle();
    }
    
    createNewTab() {
        const newTabId = this.tabs.length > 0 ? Math.max(...this.tabs.map(t => t.id)) + 1 : 1;
        const newTab = this.setupTab(newTabId);
        this.switchTab(newTabId);
        return newTab;
    }
    
    closeTab(tabId) {
        if (this.tabs.length <= 1) {
            // Don't close the last tab
            return;
        }
        
        const tabIndex = this.tabs.findIndex(tab => tab.id === tabId);
        const tabElement = document.querySelector(`.tab[data-tab-id="${tabId}"]`);
        
        // Remove tab from array
        this.tabs.splice(tabIndex, 1);
        
        // Remove tab element
        tabElement.remove();
        
        // Switch to another tab if closing active tab
        if (tabId === this.activeTabId) {
            const newActiveTabId = this.tabs[Math.max(0, tabIndex - 1)].id;
            this.switchTab(newActiveTabId);
        }
    }
    
    async navigateTo(url) {
        let finalUrl = url.trim();
        
        // Add protocol if missing
        if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
            if (finalUrl.includes('.') && !finalUrl.includes(' ')) {
                finalUrl = 'https://' + finalUrl;
            } else {
                // It's a search query
                const searchEngine = this.settings.searchEngine || 'google';
                const searchUrls = {
                    google: 'https://www.google.com/search?q=',
                    bing: 'https://www.bing.com/search?q=',
                    duckduckgo: 'https://duckduckgo.com/?q=',
                    yahoo: 'https://search.yahoo.com/search?p='
                };
                finalUrl = searchUrls[searchEngine] + encodeURIComponent(finalUrl);
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
        activeTab.isLoading = true;
        
        // Update URL bar
        this.urlBar.value = finalUrl;
        
        // Navigate
        await this.showWebView(finalUrl);
        this.updateSecurityIcon(finalUrl);
        this.updateNavigationButtons();
        this.updateWindowTitle();
        
        // Add to recent sites
        this.addRecentSite(finalUrl);
    }
    
    navigate() {
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
    
    async showWebView(url) {
        // Hide new tab page, show webview
        this.newTabPage.classList.remove('active');
        this.webviewContainer.style.display = 'block';
        this.webviewOverlay.style.display = 'flex';
        
        // Update status
        this.statusText.textContent = `Loading ${url}...`;
        
        try {
            // Use proxy for cross-origin requests
            if (this.isRender && this.useProxy) {
                const proxyUrl = `/api/proxy?url=${encodeURIComponent(url)}`;
                
                // Load via proxy
                this.webview.src = proxyUrl;
            } else {
                // Direct load (may be blocked by CORS)
                this.webview.src = url;
            }
            
            // Hide overlay after a delay
            setTimeout(() => {
                this.webviewOverlay.style.display = 'none';
            }, 2000);
            
        } catch (error) {
            console.error('Error loading page:', error);
            this.showErrorPage(`Failed to load: ${url}`, error.message);
        }
    }
    
    showErrorPage(url, error) {
        const errorHTML = `
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Error Loading Page</title>
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        min-height: 100vh;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        padding: 20px;
                        margin: 0;
                    }
                    .error-container {
                        background: rgba(255, 255, 255, 0.1);
                        backdrop-filter: blur(10px);
                        border-radius: 20px;
                        padding: 40px;
                        max-width: 600px;
                        text-align: center;
                        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
                        border: 1px solid rgba(255, 255, 255, 0.2);
                    }
                    h1 {
                        font-size: 48px;
                        margin-bottom: 20px;
                        font-weight: 700;
                    }
                    h2 {
                        font-size: 24px;
                        margin-bottom: 20px;
                        opacity: 0.9;
                    }
                    p {
                        font-size: 16px;
                        margin-bottom: 30px;
                        opacity: 0.8;
                        line-height: 1.6;
                    }
                    .error-details {
                        background: rgba(0, 0, 0, 0.2);
                        padding: 15px;
                        border-radius: 10px;
                        margin-bottom: 30px;
                        font-family: monospace;
                        text-align: left;
                        font-size: 14px;
                        overflow-x: auto;
                    }
                    .buttons {
                        display: flex;
                        gap: 10px;
                        justify-content: center;
                        flex-wrap: wrap;
                    }
                    .btn {
                        padding: 12px 24px;
                        border-radius: 50px;
                        text-decoration: none;
                        font-weight: 600;
                        transition: all 0.3s;
                        border: none;
                        cursor: pointer;
                        font-size: 16px;
                    }
                    .btn-primary {
                        background: white;
                        color: #667eea;
                    }
                    .btn-primary:hover {
                        transform: translateY(-2px);
                        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
                    }
                    .btn-secondary {
                        background: transparent;
                        color: white;
                        border: 2px solid white;
                    }
                    .btn-secondary:hover {
                        background: rgba(255, 255, 255, 0.1);
                    }
                    .error-icon {
                        font-size: 64px;
                        margin-bottom: 20px;
                        opacity: 0.8;
                    }
                </style>
            </head>
            <body>
                <div class="error-container">
                    <div class="error-icon">⚠️</div>
                    <h1>Unable to Load Page</h1>
                    <h2>${new URL(url).hostname}</h2>
                    <p>This website may be blocking proxy requests or is temporarily unavailable.</p>
                    
                    <div class="error-details">
                        <strong>URL:</strong> ${url}<br>
                        <strong>Error:</strong> ${error || 'Unknown error'}
                    </div>
                    
                    <div class="buttons">
                        <button class="btn btn-primary" onclick="window.location.reload()">
                            Try Again
                        </button>
                        <button class="btn btn-secondary" onclick="window.location.href = '/'">
                            Go Home
                        </button>
                        <button class="btn btn-secondary" onclick="window.open('${url}', '_blank')">
                            Open in New Tab
                        </button>
                    </div>
                </div>
                <script>
                    // Make buttons work in iframe
                    document.querySelectorAll('.btn').forEach(btn => {
                        btn.addEventListener('click', function() {
                            if (this.getAttribute('onclick')) {
                                eval(this.getAttribute('onclick'));
                            }
                        });
                    });
                </script>
            </body>
            </html>
        `;
        
        this.webview.srcdoc = errorHTML;
        this.webviewOverlay.style.display = 'none';
        this.statusText.textContent = 'Error loading page';
    }
    
    showNewTabPage() {
        this.webviewContainer.style.display = 'none';
        this.newTabPage.classList.add('active');
        this.statusText.textContent = 'New Tab';
        this.urlBar.value = '';
        this.securityIcon.className = 'fas fa-lock url-icon';
        this.pageInfo.textContent = '';
        
        // Update recent sites
        this.updateRecentSites();
    }
    
    goBack() {
        const activeTab = this.getActiveTab();
        if (activeTab.historyIndex > 0) {
            activeTab.historyIndex--;
            const url = activeTab.history[activeTab.historyIndex];
            activeTab.url = url;
            this.urlBar.value = url;
            this.showWebView(url);
            this.updateSecurityIcon(url);
            this.updateNavigationButtons();
            this.updateWindowTitle();
        }
    }
    
    goForward() {
        const activeTab = this.getActiveTab();
        if (activeTab.historyIndex < activeTab.history.length - 1) {
            activeTab.historyIndex++;
            const url = activeTab.history[activeTab.historyIndex];
            activeTab.url = url;
            this.urlBar.value = url;
            this.showWebView(url);
            this.updateSecurityIcon(url);
            this.updateNavigationButtons();
            this.updateWindowTitle();
        }
    }
    
    reload() {
        const activeTab = this.getActiveTab();
        if (activeTab.url !== 'about:newtab') {
            this.webview.src = this.webview.src;
            this.webviewOverlay.style.display = 'flex';
            this.statusText.textContent = 'Reloading...';
        }
    }
    
    goHome() {
        this.createNewTab();
    }
    
    clearUrlBar() {
        this.urlBar.value = '';
        this.searchSuggestions.style.display = 'none';
    }
    
    updateTabTitle(tabId, title) {
        const tab = this.tabs.find(t => t.id === tabId);
        if (tab) {
            tab.title = title.substring(0, 30) + (title.length > 30 ? '...' : '');
            const tabElement = document.querySelector(`.tab[data-tab-id="${tabId}"] .tab-title`);
            if (tabElement) {
                tabElement.textContent = tab.title;
            }
        }
    }
    
    updateSecurityIcon(url) {
        if (url.startsWith('https://')) {
            this.securityIcon.className = 'fas fa-lock url-icon';
            this.securityIcon.style.color = '#34a853';
        } else if (url.startsWith('http://')) {
            this.securityIcon.className = 'fas fa-exclamation-triangle url-icon';
            this.securityIcon.style.color = '#fbbc05';
        } else {
            this.securityIcon.className = 'fas fa-globe url-icon';
            this.securityIcon.style.color = '#9aa0a6';
        }
    }
    
    updateNavigationButtons() {
        const activeTab = this.getActiveTab();
        this.btnBack.disabled = !(activeTab.historyIndex > 0);
        this.btnForward.disabled = !(activeTab.historyIndex < activeTab.history.length - 1);
    }
    
    onPageLoad() {
        const activeTab = this.getActiveTab();
        if (activeTab && activeTab.url !== 'about:newtab') {
            this.statusText.textContent = 'Done';
            activeTab.isLoading = false;
            this.webviewOverlay.style.display = 'none';
            
            // Try to get page title from iframe
            try {
                const iframeDoc = this.webview.contentDocument || this.webview.contentWindow.document;
                const title = iframeDoc.title || new URL(activeTab.url).hostname;
                this.updateTabTitle(activeTab.id, title);
                this.pageInfo.textContent = `${title} - ${new URL(activeTab.url).hostname}`;
            } catch (e) {
                // Cross-origin restrictions
                const hostname = new URL(activeTab.url).hostname;
                this.updateTabTitle(activeTab.id, hostname);
                this.pageInfo.textContent = hostname;
            }
        }
        
        // Update window title
        this.updateWindowTitle();
    }
    
    onPageError() {
        this.statusText.textContent = 'Failed to load page';
        this.webviewOverlay.style.display = 'none';
        const activeTab = this.getActiveTab();
        if (activeTab) {
            activeTab.isLoading = false;
        }
    }
    
    zoomIn() {
        if (this.zoomLevel < 300) {
            this.zoomLevel += 25;
            this.updateZoom();
        }
    }
    
    zoomOut() {
        if (this.zoomLevel > 25) {
            this.zoomLevel -= 25;
            this.updateZoom();
        }
    }
    
    zoomReset() {
        this.zoomLevel = 100;
        this.updateZoom();
    }
    
    updateZoom() {
        this.webview.style.zoom = `${this.zoomLevel}%`;
        this.zoomLevelDisplay.textContent = `${this.zoomLevel}%`;
        document.getElementById('zoom-value').textContent = `${this.zoomLevel}%`;
        document.getElementById('zoom-slider').value = this.zoomLevel;
    }
    
    toggleFullscreen() {
        if (!document.fullscreenElement) {
            document.documentElement.requestFullscreen().catch(err => {
                console.log(`Error attempting to enable fullscreen: ${err.message}`);
            });
        } else {
            if (document.exitFullscreen) {
                document.exitFullscreen();
            }
        }
    }
    
    async handleSearchInput(query) {
        if (query.length < 2) {
            this.searchSuggestions.style.display = 'none';
            return;
        }
        
        try {
            const response = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
            const data = await response.json();
            
            if (data.suggestions && data.suggestions.length > 0) {
                this.searchSuggestions.innerHTML = data.suggestions.map(suggestion => `
                    <div class="search-suggestion" data-query="${suggestion}">
                        <i class="fas fa-search"></i>
                        <span>${suggestion}</span>
                    </div>
                `).join('');
                
                this.searchSuggestions.style.display = 'block';
                
                // Add event listeners to suggestions
                document.querySelectorAll('.search-suggestion').forEach(suggestion => {
                    suggestion.addEventListener('click', () => {
                        const query = suggestion.dataset.query;
                        this.urlBar.value = query;
                        this.navigateTo(query);
                        this.searchSuggestions.style.display = 'none';
                    });
                });
            } else {
                this.searchSuggestions.style.display = 'none';
            }
        } catch (error) {
            console.error('Error fetching search suggestions:', error);
            this.searchSuggestions.style.display = 'none';
        }
    }
    
    showBookmarksModal() {
        this.modalOverlay.style.display = 'block';
        this.bookmarksModal.style.display = 'flex';
        this.renderBookmarks();
    }
    
    showSettingsModal() {
        this.modalOverlay.style.display = 'block';
        this.settingsModal.style.display = 'flex';
        this.loadSettingsIntoForm();
    }
    
    showMenu() {
        // Simple menu implementation
        const menuItems = [
            { icon: 'fa-bookmark', text: 'Bookmarks', action: () => this.showBookmarksModal() },
            { icon: 'fa-history', text: 'History', action: () => this.showToast('History feature coming soon', 'info') },
            { icon: 'fa-download', text: 'Downloads', action: () => this.showToast('Downloads feature coming soon', 'info') },
            { icon: 'fa-cog', text: 'Settings', action: () => this.showSettingsModal() },
            { icon: 'fa-question-circle', text: 'Help', action: () => this.navigateTo('https://github.com/yourusername/web-browser') },
            { icon: 'fa-moon', text: 'Toggle Theme', action: () => this.toggleTheme() }
        ];
        
        // Create menu element
        const menu = document.createElement('div');
        menu.className = 'dropdown-menu';
        menu.style.cssText = `
            position: absolute;
            top: 50px;
            right: 10px;
            background: var(--surface-color);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            min-width: 200px;
            z-index: 1000;
        `;
        
        menu.innerHTML = menuItems.map(item => `
            <div class="menu-item" style="padding: 12px 16px; cursor: pointer; display: flex; align-items: center; gap: 12px; transition: background 0.2s;">
                <i class="fas ${item.icon}" style="color: var(--text-secondary);"></i>
                <span>${item.text}</span>
            </div>
        `).join('');
        
        // Add event listeners
        menu.querySelectorAll('.menu-item').forEach((item, index) => {
            item.addEventListener('click', () => {
                menuItems[index].action();
                menu.remove();
            });
        });
        
        // Add click outside to close
        const closeMenu = (e) => {
            if (!menu.contains(e.target) && e.target !== this.btnMenu) {
                menu.remove();
                document.removeEventListener('click', closeMenu);
            }
        };
        
        document.body.appendChild(menu);
        setTimeout(() => document.addEventListener('click', closeMenu), 0);
    }
    
    closeModals() {
        this.modalOverlay.style.display = 'none';
        this.bookmarksModal.style.display = 'none';
        this.settingsModal.style.display = 'none';
    }
    
    loadSettings() {
        const savedSettings = localStorage.getItem('browser-settings');
        if (savedSettings) {
            this.settings = JSON.parse(savedSettings);
            this.theme = this.settings.theme || 'dark';
            this.useProxy = this.settings.useProxy !== false;
        } else {
            this.settings = {
                theme: 'dark',
                searchEngine: 'google',
                useProxy: true,
                blockAds: true,
                blockTrackers: true
            };
        }
    }
    
    saveSettings() {
        this.settings.theme = this.theme;
        this.settings.useProxy = document.getElementById('use-proxy').checked;
        this.settings.searchEngine = document.getElementById('search-engine').value;
        this.settings.blockAds = document.getElementById('block-ads').checked;
        this.settings.blockTrackers = document.getElementById('block-trackers').checked;
        
        localStorage.setItem('browser-settings', JSON.stringify(this.settings));
        this.applyTheme();
    }
    
    loadSettingsIntoForm() {
        document.getElementById('use-proxy').checked = this.settings.useProxy !== false;
        document.getElementById('search-engine').value = this.settings.searchEngine || 'google';
        document.getElementById('block-ads').checked = this.settings.blockAds !== false;
        document.getElementById('block-trackers').checked = this.settings.blockTrackers !== false;
        
        // Update theme options
        document.querySelectorAll('.theme-option').forEach(option => {
            option.classList.remove('active');
            if (option.dataset.theme === this.theme) {
                option.classList.add('active');
            }
        });
    }
    
    switchSettingsTab(tabName) {
        document.querySelectorAll('.settings-tab').forEach(tab => {
            tab.classList.remove('active');
        });
        document.querySelectorAll('.settings-pane').forEach(pane => {
            pane.classList.remove('active');
        });
        
        document.querySelector(`.settings-tab[data-tab="${tabName}"]`).classList.add('active');
        document.querySelector(`.settings-pane[data-pane="${tabName}"]`).classList.add('active');
    }
    
    setTheme(theme) {
        this.theme = theme;
        document.documentElement.setAttribute('data-theme', theme);
        document.querySelectorAll('.theme-option').forEach(option => {
            option.classList.remove('active');
            if (option.dataset.theme === theme) {
                option.classList.add('active');
            }
        });
    }
    
    toggleTheme() {
        this.theme = this.theme === 'dark' ? 'light' : 'dark';
        this.setTheme(this.theme);
        this.showToast(`Switched to ${this.theme} theme`, 'success');
    }
    
    applyTheme() {
        document.documentElement.setAttribute('data-theme', this.theme);
    }
    
    loadBookmarks() {
        const savedBookmarks = localStorage.getItem('browser-bookmarks');
        if (savedBookmarks) {
            this.bookmarks = JSON.parse(savedBookmarks);
        } else {
            this.bookmarks = [
                { name: 'Google', url: 'https://www.google.com', icon: 'fab fa-google' },
                { name: 'YouTube', url: 'https://www.youtube.com', icon: 'fab fa-youtube' },
                { name: 'GitHub', url: 'https://github.com', icon: 'fab fa-github' },
                { name: 'ChatGPT', url: 'https://chat.openai.com', icon: 'fas fa-robot' },
                { name: 'Wikipedia', url: 'https://www.wikipedia.org', icon: 'fab fa-wikipedia-w' }
            ];
        }
    }
    
    saveBookmarks() {
        localStorage.setItem('browser-bookmarks', JSON.stringify(this.bookmarks));
    }
    
    toggleBookmark() {
        const activeTab = this.getActiveTab();
        if (!activeTab || activeTab.url === 'about:newtab') {
            this.showToast('Cannot bookmark this page', 'warning');
            return;
        }
        
        const existingIndex = this.bookmarks.findIndex(b => b.url === activeTab.url);
        
        if (existingIndex > -1) {
            this.bookmarks.splice(existingIndex, 1);
            this.btnFavorite.innerHTML = '<i class="far fa-star"></i>';
            this.showToast('Bookmark removed', 'success');
        } else {
            const name = activeTab.title || new URL(activeTab.url).hostname;
            this.bookmarks.unshift({
                name,
                url: activeTab.url,
                icon: this.getFaviconForUrl(activeTab.url)
            });
            this.btnFavorite.innerHTML = '<i class="fas fa-star"></i>';
            this.showToast('Bookmark added', 'success');
        }
        
        this.saveBookmarks();
    }
    
    getFaviconForUrl(url) {
        const hostname = new URL(url).hostname;
        if (hostname.includes('google.com')) return 'fab fa-google';
        if (hostname.includes('youtube.com')) return 'fab fa-youtube';
        if (hostname.includes('github.com')) return 'fab fa-github';
        if (hostname.includes('wikipedia.org')) return 'fab fa-wikipedia-w';
        if (hostname.includes('twitter.com')) return 'fab fa-twitter';
        if (hostname.includes('facebook.com')) return 'fab fa-facebook';
        if (hostname.includes('amazon.com')) return 'fab fa-amazon';
        if (hostname.includes('netflix.com')) return 'fab fa-netflix';
        return 'fas fa-globe';
    }
    
    renderBookmarks() {
        const bookmarksList = document.getElementById('bookmarks-list');
        bookmarksList.innerHTML = this.bookmarks.map((bookmark, index) => `
            <div class="bookmark-item" data-index="${index}">
                <i class="${bookmark.icon}"></i>
                <div class="bookmark-info">
                    <div class="bookmark-name">${bookmark.name}</div>
                    <div class="bookmark-url">${bookmark.url}</div>
                </div>
                <div class="bookmark-actions">
                    <button class="bookmark-visit" data-index="${index}" title="Visit">
                        <i class="fas fa-external-link-alt"></i>
                    </button>
                    <button class="bookmark-remove" data-index="${index}" title="Remove">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
        `).join('');
        
        // Add event listeners
        bookmarksList.querySelectorAll('.bookmark-item').forEach(item => {
            item.addEventListener('click', (e) => {
                if (!e.target.closest('.bookmark-actions')) {
                    const index = parseInt(item.dataset.index);
                    this.navigateTo(this.bookmarks[index].url);
                    this.closeModals();
                }
            });
        });
        
        bookmarksList.querySelectorAll('.bookmark-visit').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const index = parseInt(btn.dataset.index);
                this.navigateTo(this.bookmarks[index].url);
                this.closeModals();
            });
        });
        
        bookmarksList.querySelectorAll('.bookmark-remove').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const index = parseInt(btn.dataset.index);
                this.bookmarks.splice(index, 1);
                this.saveBookmarks();
                this.renderBookmarks();
                this.showToast('Bookmark removed', 'success');
            });
        });
    }
    
    addRecentSite(url) {
        const recentSites = JSON.parse(localStorage.getItem('recent-sites') || '[]');
        const siteInfo = {
            url,
            title: new URL(url).hostname,
            icon: this.getFaviconForUrl(url),
            timestamp: new Date().toISOString()
        };
        
        // Remove if already exists
        const existingIndex = recentSites.findIndex(site => site.url === url);
        if (existingIndex > -1) {
            recentSites.splice(existingIndex, 1);
        }
        
        // Add to beginning
        recentSites.unshift(siteInfo);
        
        // Keep only last 10
        if (recentSites.length > 10) {
            recentSites.pop();
        }
        
        localStorage.setItem('recent-sites', JSON.stringify(recentSites));
    }
    
    updateRecentSites() {
        const recentSites = JSON.parse(localStorage.getItem('recent-sites') || '[]');
        this.recentSites.innerHTML = recentSites.map(site => `
            <div class="recent-site" data-url="${site.url}">
                <i class="${site.icon}"></i>
                <div class="recent-site-info">
                    <div class="recent-site-title">${site.title}</div>
                    <div class="recent-site-url">${site.url}</div>
                </div>
            </div>
        `).join('');
        
        // Add event listeners
        this.recentSites.querySelectorAll('.recent-site').forEach(site => {
            site.addEventListener('click', () => {
                const url = site.dataset.url;
                this.navigateTo(url);
            });
        });
    }
    
    updateWindowTitle() {
        const activeTab = this.getActiveTab();
        if (activeTab && activeTab.url !== 'about:newtab') {
            this.windowTitle.textContent = `${activeTab.title} - Web Browser`;
        } else {
            this.windowTitle.textContent = 'Web Browser';
        }
    }
    
    handleKeyboardShortcuts(e) {
        // Ctrl/Cmd + T - New Tab
        if ((e.ctrlKey || e.metaKey) && e.key === 't') {
            e.preventDefault();
            this.createNewTab();
        }
        
        // Ctrl/Cmd + W - Close Tab
        if ((e.ctrlKey || e.metaKey) && e.key === 'w') {
            e.preventDefault();
            const activeTab = this.getActiveTab();
            if (activeTab) {
                this.closeTab(activeTab.id);
            }
        }
        
        // Ctrl/Cmd + Tab - Next Tab
        if ((e.ctrlKey || e.metaKey) && e.key === 'Tab') {
            e.preventDefault();
            const currentIndex = this.tabs.findIndex(tab => tab.id === this.activeTabId);
            const nextIndex = (currentIndex + 1) % this.tabs.length;
            this.switchTab(this.tabs[nextIndex].id);
        }
        
        // Ctrl/Cmd + L - Focus URL Bar
        if ((e.ctrlKey || e.metaKey) && e.key === 'l') {
            e.preventDefault();
            this.urlBar.focus();
            this.urlBar.select();
        }
        
        // F5 or Ctrl/Cmd + R - Reload
        if (e.key === 'F5' || ((e.ctrlKey || e.metaKey) && e.key === 'r')) {
            e.preventDefault();
            this.reload();
        }
        
        // Ctrl/Cmd + D - Bookmark
        if ((e.ctrlKey || e.metaKey) && e.key === 'd') {
            e.preventDefault();
            this.toggleBookmark();
        }
        
        // Ctrl/Cmd + + - Zoom In
        if ((e.ctrlKey || e.metaKey) && (e.key === '+' || e.key === '=')) {
            e.preventDefault();
            this.zoomIn();
        }
        
        // Ctrl/Cmd + - - Zoom Out
        if ((e.ctrlKey || e.metaKey) && e.key === '-') {
            e.preventDefault();
            this.zoomOut();
        }
        
        // Ctrl/Cmd + 0 - Reset Zoom
        if ((e.ctrlKey || e.metaKey) && e.key === '0') {
            e.preventDefault();
            this.zoomReset();
        }
    }
    
    showToast(message, type = 'info') {
        this.toast.textContent = message;
        this.toast.className = `toast ${type}`;
        this.toast.classList.add('show');
        
        setTimeout(() => {
            this.toast.classList.remove('show');
        }, 3000);
    }
    
    updateUI() {
        // Update zoom level display
        this.zoomLevelDisplay.textContent = `${this.zoomLevel}%`;
        document.getElementById('zoom-value').textContent = `${this.zoomLevel}%`;
        document.getElementById('zoom-slider').value = this.zoomLevel;
        
        // Update theme
        this.applyTheme();
        
        // Update recent sites
        this.updateRecentSites();
    }
}

// Initialize the browser when the page loads
window.addEventListener('DOMContentLoaded', () => {
    const browser = new WebBrowser();
    
    // Make browser available globally for debugging
    window.browser = browser;
    
    // Show welcome message
    setTimeout(() => {
        browser.showToast('Welcome to Web Browser! Press F1 for keyboard shortcuts.', 'info');
    }, 1000);
});
