# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=720 \
    VNC_PASSWORD=chrome123 \
    CHROME_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --remote-debugging-port=9222 --window-size=1280,720 --start-maximized" \
    ENABLE_AUTH=false \
    AUTH_USER=admin \
    AUTH_PASS=admin123

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    software-properties-common \
    xvfb \
    x11vnc \
    supervisor \
    fluxbox \
    novnc \
    net-tools \
    git \
    curl \
    nginx \
    apache2-utils \
    python3 \
    python3-pip \
    vim \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome Browser
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install Firefox (optional)
RUN apt-get update && apt-get install -y firefox && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash chrome \
    && echo 'chrome:chrome' | chpasswd \
    && mkdir -p /home/chrome/.config \
    && chown -R chrome:chrome /home/chrome

# Install noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && ln -s /opt/noVNC/vnc_lite.html /opt/noVNC/index.html

# Create necessary directories
RUN mkdir -p /data/chrome /var/log/supervisor \
    && chmod 777 /data /var/log/supervisor \
    && chown -R chrome:chrome /data/chrome

# Copy configuration files
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY start.sh /start.sh

# Set permissions
RUN chmod +x /start.sh \
    && chown -R chrome:chrome /opt/noVNC

# Expose ports
EXPOSE 80 5900 6080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start the service
CMD ["/start.sh"]
# ... existing Dockerfile content ...

# Copy keep-alive script
COPY keep-alive.sh /keep-alive.sh
RUN chmod +x /keep-alive.sh

# Add startup command to start keep-alive
CMD ["bash", "-c", "/start.sh & /keep-alive.sh"]
