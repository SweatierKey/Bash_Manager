#!/bin/bash

# SSH Password Manager

# Function to securely read password
read_password() {
    read -s -p "Enter SSH password: " password
    echo
}

# Function to save password to a file
save_password() {
    echo "$password" > ~/.ssh_password
    echo "Password saved securely."
}

# Function to retrieve password
get_password() {
    if [[ -f ~/.ssh_password ]]; then
        password=$(cat ~/.ssh_password)
        echo "Retrieved password."
    else
        echo "No password found. Please save it first."
    fi
}

# Function to delete password
delete_password() {
    if [[ -f ~/.ssh_password ]]; then
        rm ~/.ssh_password
        echo "Password deleted."
    else
        echo "No password found to delete."
    fi
}

# Main menu
while true; do
    echo "Select an option:"
    echo "1. Save SSH password"
    echo "2. Retrieve SSH password"
    echo "3. Delete SSH password"
    echo "4. Exit"
    read -p "Choice: " choice

    case $choice in
        1)
            read_password
            save_password
            ;;
        2)
            get_password
            ;;
        3)
            delete_password
            ;;
        4)
            echo "Exiting."
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
