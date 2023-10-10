#!/bin/bash

invalidchoices=0

while [ $invalidchoices -lt 2 ]; do
    echo "Please choose the type of backup you want to set up:"
    echo "1. Exchange"
    echo "2. OneDrive"
    echo "3. SharePoint"

    read -p "Enter the number of your choice (1/2/3): " choice

    case $choice in
        1)
            ./setupexchange.sh ;;
        2)
            ./setuponedrive.sh ;;
        3)
            ./setupsharepoint.sh ;;
        *)
            echo "Invalid choice. Please enter a valid option (1/2/3)."
            ((invalidchoices++)) ;;
    esac
done

echo "Invalid choice selected twice. Exiting..."
