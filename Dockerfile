FROM ubuntu:22.04

# Set environment variables for non-interactive install and display setup
# DBUS_SESSION_BUS_ADDRESS is now set here for all subsequent RUN commands.
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    DISPLAY=:99 \
    DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=720 \
    VNC_PORT=5900 \
    WEB_PORT=80 \
    DBUS_SESSION_BUS_ADDRESS=/dev/null 

# FIX: Stable installation command: use --fix-missing and --fix-broken 
# to resolve dependency issues like the Git daemons, and remove the problematic flag.
RUN apt-get update && \
    apt-get install -y --no-install-recommends --allow-unauthenticated **--fix-missing --fix-broken** wget gnupg ca-certificates xvfb x11vnc fluxbox novnc websockify net-tools curl **git** \
    && rm -rf /var/lib/apt/lists/*

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
