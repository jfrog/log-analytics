#!/bin/bash

# Array of environment variables to check
env_vars=$1

# Function to check if an environment variable is set
check_env_variable() {
    if [ -z "${!1}" ]; then
        echo "Error: $1 is not set."
        exit 1
    else
        echo "$1 is set."
    fi
}

# Check each environment variable
for var in "${env_vars[@]}"; do
    check_env_variable "$var"
done

echo "All required environment variables are set."