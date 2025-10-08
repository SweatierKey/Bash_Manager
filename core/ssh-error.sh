#!/bin/bash

# SSH Error Handling and Retry Logic

# Function to execute SSH command with retries
ssh_with_retries() {
    local retries=5
    local count=0
    local command="$1"

    until [ "$count" -ge "$retries" ]; do
        # Execute the SSH command
        eval "$command"

        # Check if the command was successful
        if [ $? -eq 0 ]; then
            echo "Command succeeded!"
            return 0
        fi

        echo "Command failed, retrying in 2 seconds..."
        sleep 2
        count=$((count + 1))
    done

    echo "Command failed after $retries attempts."
    return 1
}

# Example usage
# ssh_with_retries "ssh user@host 'your-command'"