FROM ubuntu:22.04

# Set non-interactive frontend to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive \
    DBUS_SESSION_BUS_ADDRESS=/dev/null \
    NO_AT_BRIDGE=1 \
    DISPLAY=:99 \
    DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=720

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    websockify \
    net-tools \
    curl \
    git \
    python3 \
    python3-numpy \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome (without recommended packages to reduce size)
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for Chrome
RUN useradd -m -s /bin/bash chrome \
    && echo 'chrome:chrome' | chpasswd \
    && mkdir -p /home/chrome/.config \
    && chown -R chrome:chrome /home/chrome

# Create data directory for persistent storage
RUN mkdir -p /data/chrome /data/downloads \
    && chown -R chrome:chrome /data \
    && chmod 755 /data

# Install noVNC from source (better control)
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
    && ln -s /opt/noVNC/vnc_lite.html /opt/noVNC/index.html

# Create custom HTML interface
RUN mkdir -p /opt/noVNC/custom \
    && echo '<!DOCTYPE html><html><head><title>Chrome RDP</title><meta http-equiv="refresh" content="0; url=/vnc_lite.html"></head><body><p>Redirecting to VNC client...</p></body></html>' > /opt/noVNC/custom/redirect.html

# Create health check endpoint
RUN echo 'OK' > /opt/noVNC/health.html

# Copy startup script and make it executable
COPY start.sh /start.sh
RUN chmod +x /start.sh  # 👈 THIS MAKES THE SCRIPT EXECUTABLE

# Clean up to reduce image size
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && rm -rf /usr/share/doc/* /usr/share/man/*

# Expose port 80 for web access
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/health.html || exit 1

# Start the service
CMD ["/start.sh"]
