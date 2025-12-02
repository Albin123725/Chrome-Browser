# Chrome Cloud RDP

Deploy a full Chrome browser in the cloud with RDP/VNC access. Perfect for running Google Colab, web automation, or remote browsing.

## 🌟 Features

- **Full Chrome Browser** - Real Chrome, not limited by iframes
- **VNC/Web Access** - Access from any device via browser
- **Google Colab Ready** - Your notebook pre-loaded
- **Persistent Storage** - Save bookmarks, downloads, settings
- **Free Tier Compatible** - Works on Render's free plan
- **Auto Password Generation** - Secure by default
- **Health Monitoring** - Auto-restart on failure
- **Mobile Friendly** - Responsive web interface

## 🚀 Quick Deploy on Render

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

1. **Fork this repo** to your GitHub account
2. **Click "Deploy to Render" button above**
3. **Configure** (or use defaults):
   - Name: `chrome-rdp` (or your preferred name)
   - Plan: `Free`
4. **Click "Create Web Service"**
5. **Wait 3-5 minutes** for deployment

## 🔑 Access Credentials

After deployment:

1. **Web Interface**: `https://your-app.onrender.com`
2. **VNC Client**: Connect to `your-app.onrender.com:5900`

**Default Credentials** (check Render logs):
- **VNC Password**: Auto-generated (see logs)
- **Web Auth**: `admin` / auto-generated password

## ⚙️ Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DISPLAY_WIDTH` | 1280 | Screen width |
| `DISPLAY_HEIGHT` | 720 | Screen height |
| `VNC_PASSWORD` | auto-generated | VNC access password |
| `ENABLE_AUTH` | true | Enable web authentication |
| `AUTH_USER` | admin | Web auth username |
| `AUTH_PASS` | auto-generated | Web auth password |
| `STARTUP_URL` | Your Colab URL | URL to open on startup |
| `CHROME_FLAGS` | Optimized flags | Chrome command line flags |

## 🖥️ Usage Guide

### Open Google Colab
1. Access your RDP
2. Click Chrome icon
3. Go to: `https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1`

### Keyboard Shortcuts
- **Ctrl+Alt+Del**: Open task manager
- **Alt+F4**: Close window
- **Alt+Tab**: Switch windows
- **Ctrl+T**: New tab (in Chrome)

### File Transfer
- **Upload**: Use web interface file upload
- **Download**: Files saved to `/data/downloads`
- **Persistent**: All data in `/data` persists

## 🔧 Local Development

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/chrome-rdp.git
cd chrome-rdp

# Build and run locally
docker-compose up

# Access at http://localhost:8080
# VNC password: chrome123
