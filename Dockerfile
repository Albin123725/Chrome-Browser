FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install everything
RUN apt-get update && apt-get install -y \
    wget gnupg xvfb x11vnc fluxbox novnc websockify curl \
    python3 python3-websockify \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC properly
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC --depth 1 \
    && git clone https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify --depth 1

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
