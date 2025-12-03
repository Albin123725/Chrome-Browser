FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget gnupg xvfb x11vnc fluxbox novnc websockify curl nodejs npm \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js if not already
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Copy files
COPY start.sh /start.sh
RUN chmod +x /start.sh

COPY server.js /server.js
COPY package.json /package.json

RUN npm install

EXPOSE 3000 80

CMD ["/start.sh"]
