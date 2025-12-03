FROM ubuntu:22.04

# Set environment to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    DBUS_SESSION_BUS_ADDRESS=/dev/null \
    NO_AT_BRIDGE=1

# Install minimal packages
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    curl \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome without recommended packages (reduces errors)
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash chrome

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Create health check endpoint
RUN echo 'OK' > /var/www/html/health

# Expose port
EXPOSE 80

# Start
CMD ["/start.sh"]
