#!/bin/bash

# Basic SSH connectivity test
function basic_ping() {
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$1" exit
    if [ $? -eq 0 ]; then
        echo "Connection to $1 succeeded."
    else
        echo "Connection to $1 failed."
    fi
}

# Detailed ping with system info
function detailed_ping() {
    local host="$1"
    if basic_ping "$host"; then
        echo "System Info for $host:"
        ssh "$host" "uname -a; uptime"
    fi
}

# Quick port connectivity test
function port_test() {
    local host="$1"
    local port="$2"
    nc -z -w5 "$host" "$port"
    if [ $? -eq 0 ]; then
        echo "Port $port on $host is open."
    else
        echo "Port $port on $host is closed."
    fi
}

# Test multiple hosts from a file
function multi_host_test() {
    local file="$1"
    while IFS= read -r host; do
        basic_ping "$host"
    done < "$file"
}

# Integration with ssh-password-manager.sh (Assuming this module has a function get_password)
function connect_with_password() {
    local host="$1"
    local password=$(./ssh-password-manager.sh get_password "$host")
    sshpass -p "$password" ssh "$host" exit
}

# Main function to handle command line arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 {basic|detailed|port|multi-host|connect} [args...]"
    exit 1
fi

case "$1" in
    basic)
        basic_ping "$2"
        ;;
    detailed)
        detailed_ping "$2"
        ;;
    port)
        port_test "$2" "$3"
        ;;
    multi-host)
        multi_host_test "$2"
        ;;
    connect)
        connect_with_password "$2"
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac
