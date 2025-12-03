FROM ubuntu:22.04

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    DBUS_SESSION_BUS_ADDRESS=/dev/null \
    NO_AT_BRIDGE=1

# Install ALL dependencies
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
    dbus \
    dbus-x11 \
    x11-utils \
    xauth \
    git \
    python3 \
    python3-numpy \
    python3-websockify \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Clone noVNC properly
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC --depth 1 \
    && git clone https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify --depth 1 \
    && ln -s /opt/noVNC/vnc_lite.html /opt/noVNC/index.html

# Create Chrome data directory
RUN mkdir -p /home/chrome/.config/google-chrome \
    && chmod -R 755 /home/chrome

# Copy and make start script executable
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
