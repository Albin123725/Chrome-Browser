#!/bin/bash

# This script keeps Chrome and Colab running

echo "Starting keep-alive monitor..."

# Function to check if Chrome is running
check_chrome() {
    if curl -s http://localhost:9222/json/list > /dev/null 2>&1; then
        return 0  # Chrome is running
    else
        return 1  # Chrome is not running
    fi
}

# Function to check if Colab notebook is loaded
check_colab() {
    if curl -s http://localhost:9222/json/list | grep -q "colab.research.google.com"; then
        return 0  # Colab is loaded
    else
        return 1  # Colab is not loaded
    fi
}

# Function to restart Chrome
restart_chrome() {
    echo "Restarting Chrome..."
    pkill -f chrome
    sleep 2
    
    google-chrome-stable \
        --no-sandbox \
        --disable-dev-shm-usage \
        --disable-gpu \
        --remote-debugging-port=9222 \
        --window-size=1280,720 \
        --start-maximized \
        --user-data-dir=/data/chrome \
        --no-first-run \
        --no-default-browser-check \
        "https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing" &
    
    sleep 10
}

# Main monitor loop
while true; do
    echo "=== Checking status at $(date) ==="
    
    # Check Chrome
    if check_chrome; then
        echo "✓ Chrome is running"
        
        # Check Colab
        if check_colab; then
            echo "✓ Colab notebook is loaded"
            
            # Keep Colab active by simulating activity
            echo "Sending keep-alive pulse to Colab..."
            
            # Get tab info
            TABS=$(curl -s http://localhost:9222/json/list)
            COLAB_TAB=$(echo "$TABS" | grep -o '"id":"[^"]*"[^}]*"colab.research.google.com"' | head -1)
            
            if [ -n "$COLAB_TAB" ]; then
                TAB_ID=$(echo "$COLAB_TAB" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
                
                # Send a harmless JavaScript command to keep tab active
                curl -s -X POST http://localhost:9222/json/command/$TAB_ID \
                    -H "Content-Type: application/json" \
                    -d '{"method":"Runtime.evaluate","params":{"expression":"console.log(\"Keep alive: \" + Date.now())","returnByValue":true},"id":1}' \
                    > /dev/null 2>&1
                
                echo "✓ Keep-alive signal sent"
            fi
        else
            echo "✗ Colab not found, reloading..."
            
            # Get Chrome tabs
            TABS=$(curl -s http://localhost:9222/json/list)
            if [ -n "$TABS" ]; then
                # Open Colab in new tab
                FIRST_TAB=$(echo "$TABS" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
                curl -s -X POST http://localhost:9222/json/new \
                    -H "Content-Type: application/json" \
                    -d "{\"url\":\"https://colab.research.google.com/drive/1jckV8xUJSmLhhol6wZwVJzpybsimiRw1?usp=sharing\"}" \
                    > /dev/null 2>&1
            fi
        fi
    else
        echo "✗ Chrome not running, restarting..."
        restart_chrome
    fi
    
    echo "Sleeping for 5 minutes..."
    sleep 300  # Check every 5 minutes
done
