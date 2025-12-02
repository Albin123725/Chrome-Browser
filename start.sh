#!/bin/bash

# Set display resolution
export DISPLAY_WIDTH=${DISPLAY_WIDTH:-1920}
export DISPLAY_HEIGHT=${DISPLAY_HEIGHT:-1080}
export DISPLAY=:99

# Set VNC password if provided
if [ -n "$VNC_PASSWORD" ]; then
    mkdir -p ~/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd
fi

# Create Chrome data directory
mkdir -p /data/chrome
chown -R chrome:chrome /data/chrome

# Set Chrome flags
export CHROME_FLAGS="--user-data-dir=/data/chrome --no-first-run --no-default-browser-check"

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
