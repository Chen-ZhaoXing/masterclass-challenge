#!/bin/bash
broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

broadcast "Setting up the environment..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  broadcast "."
done
broadcast "\n✅ The Lab is now ready!"