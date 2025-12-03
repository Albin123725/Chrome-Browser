FROM ubuntu:22.04

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=720

# Install dependencies (NO sudo needed)
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    websockify \
    curl \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Copy and make start script executable
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Create Chrome data directory
RUN mkdir -p /home/chrome/.config/google-chrome \
    && chmod -R 755 /home/chrome

EXPOSE 80

CMD ["/start.sh"]
