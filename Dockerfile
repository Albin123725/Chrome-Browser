FROM ubuntu:22.04

# Set timezone automatically to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Install all dependencies without prompts
RUN apt-get update && apt-get install -y \
    tzdata \
    wget \
    gnupg \
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    websockify \
    curl \
    nodejs \
    npm \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Copy files
COPY start.sh /start.sh
COPY server.js /server.js
COPY package.json /package.json

# Set permissions
RUN chmod +x /start.sh \
    && npm install

EXPOSE 3000 80

CMD ["/start.sh"]
