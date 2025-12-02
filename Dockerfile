FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    xvfb \
    x11vnc \
    supervisor \
    fluxbox \
    novnc \
    net-tools \
    git \
    curl \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -m -s /bin/bash chrome \
    && echo 'chrome:chrome' | chpasswd \
    && mkdir -p /home/chrome/.config \
    && chown -R chrome:chrome /home/chrome

# Copy configurations
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY start.sh /start.sh

# Setup noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Create data directory
RUN mkdir -p /data && chmod 777 /data

# Expose ports
EXPOSE 80 5900

# Make scripts executable
RUN chmod +x /start.sh

# Start
CMD ["/start.sh"]
