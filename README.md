# Cloud RDP with Chrome Browser

Deploy a full Chrome browser in the cloud with RDP access.

## Features
- Full Chrome browser in cloud
- VNC/Web access
- Persistent storage
- Free tier compatible
- One-click deploy

## Deployment on Render

1. **Fork this repository** to your GitHub account
2. **Go to Render.com** → New + → Web Service
3. **Connect your GitHub repository**
4. **Select**:
   - Name: `chrome-rdp`
   - Environment: `Docker`
   - Plan: `Free`
5. **Click "Create Web Service"**

## Access

After deployment:
1. **Web Interface**: `https://your-app.onrender.com`
2. **VNC Client**: Connect to `your-app.onrender.com:5900` (if enabled)

## Default Credentials
- **VNC Password**: Generated automatically (check Render logs)
- **Chrome**: Runs as user `chrome`

## Security Notes
- Change default passwords
- Enable authentication if needed
- Use only for development/testing

## Local Development
```bash
docker-compose up
# Access at http://localhost:8080
