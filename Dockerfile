FROM ubuntu:22.04

# ... (Environment variables remain the same) ...
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    DISPLAY=:99 \
    DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=720 \
    VNC_PORT=5900 \
    WEB_PORT=80 \
    DBUS_SESSION_BUS_ADDRESS=/dev/null 

# FIX: Added x11-utils to fix 'xmessage: not found' warning.
RUN apt-get update && \
    apt-get install -y --no-install-recommends --allow-unauthenticated wget gnupg ca-certificates xvfb x11vnc fluxbox novnc websockify net-tools curl git **x11-utils** \
    && rm -rf /var/lib/apt/lists/*
    
# ... (Rest of Dockerfile remains the same) ...
# Remove any remnants of nginx (CRITICAL FIX for "Welcome to nginx!")
RUN apt-get remove -y nginx* || true && \
    apt-get autoremove -y && \
    rm -f /etc/nginx/nginx.conf

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Copy startup script and make it executable
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose the web port
EXPOSE ${WEB_PORT}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start the service
CMD ["/start.sh"]
