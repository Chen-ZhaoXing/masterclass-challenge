#!/bin/bash

# Ensure the background setup has completed before verifying
if [ ! -f /tmp/setup-finished ]; then
    echo "Environment is still being set up. Please wait for the setup to complete before verifying."
    exit 1
fi

# Check the registry is running and accessible
curl -sf http://localhost:30500/v2/ > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Registry is running and accessible."
    exit 0
else
    echo "Registry is not accessible at localhost:30500."
    exit 1
fi
