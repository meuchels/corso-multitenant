#!/bin/bash

# Check if running as root or sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo or as root."
    exit 1
fi

# Check if there are any files in /opt/corso/
if [ -n "$(ls -A /opt/corso/scripts/)" ]; then
    read -p "It looks like there is an existing installation in /opt/corso. Do you want to proceed with reinstallation? (y/n): " proceed_with_install
    if [ "$proceed_with_install" != "y" ]; then
        read -p "Do you want to set up a new backup instead? (y/n): " setup_new_backup
        if [ "$setup_new_backup" == "y" ]; then
            /opt/corso/scripts/choosebackuptype.sh
        fi
        exit 0
    else
        read -p "WARNING!!! Are you sure you want to proceed? This will overwrite your existing installation!!!  There is no going back!!! (y/n): " confirm_overwrite
        if [ "$confirm_overwrite" != "y" ]; then
            echo "Aborted. Exiting..."
            exit 0
        fi
    fi
fi

echo "Before proceeding you will want to make sure you have configured your tenant using the instructions here https://corsobackup.io/docs/setup/m365-access/"
echo "You will also need to have gathered your credentials for AWS or compatible S3 storage and have the url."
read -p "Are you ready to proceed? (y/n):" final_continue
if [ "$final_continue" != "y" ]; then
     exit 0
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed on your system. It is recommended to install it."

    # You can add installation instructions here based on your system (e.g., apt, yum, etc.)
    # For example, on Ubuntu, you can use:
    echo "To install Git on Ubuntu, run: sudo apt-get install git"

    exit 1
fi

rm -r /opt/corso
mkdir /opt/corso

# Clone the repository to /opt/corso
git clone -q https://github.com/meuchels/corso-multitenant /opt/corso

echo "Repository cloned successfully to /opt/corso."

cd /opt/corso

# Downloading the latest version of Corso

curl -s https://api.github.com/repos/alcionai/corso/releases/latest | grep 'browser_download_url.*corso_.*_Linux_x86_64.tar.gz' | cut -d : -f 2,3 | tr -d \" | wget -i -
tar -xzvf corso_v0.14.0_Linux_x86_64.tar.gz
rm corso*.tar.gz
mkdir /opt/corso/log
mkdir /opt/corso/toml
mkdir /opt/corso/scripts/back-active



# Check if the 'secrets' file exists
if [ -f secrets ]; then
    read -p "File 'secrets' already exists. Do you want to create a new backup instead? (y/n): " create_backup_response

    if [ "$create_backup_response" == "y" ]; then
        ./scripts/choosebackuptype.sh
        exit 0
    fi

    read -p "Are you sure you want to overwrite 'secrets'? This action cannot be undone. (y/n): " final_confirmation

    if [ "$final_confirmation" != "y" ]; then
        echo "Aborted. Exiting..."
        exit 0
    fi
fi

# Prompt for user input and write to 'secrets' file
read -p "Enter AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
read -p "Enter AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
read -p "Enter CORSO_PASSPHRASE: " CORSO_PASSPHRASE
read -p "Enter s3endpoint: " s3endpoint
read -p "Enter bucket: " bucket

cat <<EOL > secrets
AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
CORSO_PASSPHRASE="$CORSO_PASSPHRASE"
s3endpoint="$s3endpoint"
bucket="$bucket"
EOL

echo "File 'secrets' created with user-provided values."

#setup backup jobs in cron

add_backup_time() {
    # Prompt user for backup time
    read -p "Enter the desired backup time (in HH:MM format, 24-hour clock): " backup_time

    # Validate the input for HH:MM format
    if ! [[ $backup_time =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        echo "Invalid time format. Please use HH:MM (24-hour clock)."
        return 1
    fi

    # Extract hours and minutes
    hours=$(echo $backup_time | cut -d':' -f1)
    minutes=$(echo $backup_time | cut -d':' -f2)

    # Validate hours and minutes
    if [[ $hours -lt 0 || $hours -gt 23 || $minutes -lt 0 || $minutes -gt 59 ]]; then
        echo "Invalid time. Please use valid HH:MM (24-hour clock) format."
        return 1
    fi

    # Add cron job
    (crontab -l ; echo "$minutes $hours * * * /opt/corso/scripts/backuprunner.sh") | crontab -

    echo "Cron job added successfully to run backups at $backup_time."
}

# Add initial backup time
add_backup_time

# Ask if you want to add another backup time
while true; do
    read -p "Do you want to add another backup time? (y/n): " add_another_time
    case $add_another_time in
        [Yy]* )
            add_backup_time
            ;;
        [Nn]* )
            break
            ;;
        * )
            echo "Please answer yes or no."
            ;;
    esac
done





# Ask if you want to create a new backup
read -p "Do you want to create a new backup? (y/n): " create_backup_response

if [ "$create_backup_response" == "y" ]; then
    ./scripts/choosebackuptype.sh
fi
