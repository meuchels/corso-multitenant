#!/bin/bash

# Check if the secrets file exists
if [ ! -f ../secrets ]; then
    echo "Error: 'secrets' file not found. Please create it with the necessary values."
    exit 1
fi

# Request user input for SHORT_TENANT_NAME
read -p "Enter a short tenant name: " TENANT_SHORT_NAME

# Request user input for AZURE_TENANT_ID
read -p "Enter your AZURE_TENANT_ID: " AZURE_TENANT_ID

# Request user input for AZURE_CLIENT_ID
read -p "Enter your AZURE_CLIENT_ID: " AZURE_CLIENT_ID

# Request user input for AZURE_CLIENT_SECRET
read -p "Enter your AZURE_CLIENT_SECRET: " AZURE_CLIENT_SECRET

# Source the secrets file
source ../secrets

# Define file paths
environment_file="./environments/$SHORT_TENANT_NAME-onedrive"
backup_file="./back-available/$SHORT_TENANT_NAME-onedrive"

# Check if environment file already exists
if [ -f "$environment_file" ]; then
    read -p "The environment file '$environment_file' already exists. Do you want to overwrite it? (y/n) " overwrite_env
    if [ "$overwrite_env" != "y" ]; then
        echo "Aborted. Exiting..."
        exit 0
    fi
fi

# Define the content of the environment file
content_environment=$(cat <<EOF
#EDIT THIS SECTION TO MEET YOUR NEEDS
#####################################
#this is a shortname for your tenant to setup storage
export tenantshortname="$TENANT_SHORT_NAME"
#this is your tenant info from the app setup on O365
export AZURE_TENANT_ID="$AZURE_TENANT_ID"
export AZURE_CLIENT_ID="$AZURE_CLIENT_ID"
export AZURE_CLIENT_SECRET="$AZURE_CLIENT_SECRET"

#this is your credentials for your s3 storage
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"

#this sets your encryption key for your backups
export CORSO_PASSPHRASE="$CORSO_PASSPHRASE"

#this is your s3 storage endpoint
export s3endpoint="$s3endpoint"
export bucket="$bucket"

####################################
#END EDIT
####################################
export configfile=/opt/corso/toml/${tenantshortname}-onedrive.toml
EOF
)

# Create the environments directory if it doesn't exist
mkdir -p ./environments

# Check if environment file already exists
if [ -f "$environment_file" ]; then
    read -p "The environment file '$environment_file' already exists. Do you want to overwrite it? (y/n) " overwrite_env
    if [ "$overwrite_env" != "y" ]; then
        echo "Aborted. Exiting..."
        exit 0
    fi
fi

# Check if backup script file already exists
if [ -f "$backup_file" ]; then
    read -p "The backup script file '$backup_file' already exists. Do you want to overwrite it? (y/n) " overwrite_backup
    if [ "$overwrite_backup" != "y" ]; then
        echo "Aborted. Exiting..."
        exit 0
    fi
fi

# Define the content of the backup script file
content_backup=$(cat <<EOF
#!/bin/bash

##############Begin Edit###

#change blank to tenant short name
source /opt/corso/scripts/environments/$TENANT_SHORT_NAME-onedrive

##############End Edit###


# create runtime variables
logfilename="/opt/corso/log/${tenantshortname}-onedrive/$(date +'%Y-%m-%d-%H%M%S').log"
runcorso="/opt/corso/corso"

# init bucket
$runcorso repo init s3 --bucket $bucket --prefix ${tenantshortname}_onedrive --endpoint $s3endpoint --log-file $logfilename --config-file $configfile --hide-progress
$runcorso repo connect s3 --bucket $bucket --log-file $logfilename --config-file $configfile --hide-progress

# Run Backup
$runcorso backup create onedrive --user '*' --log-file $logfilename --config-file $configfile --hide-progress
EOF
)

# Create the back-available directory if it doesn't exist
mkdir -p ./back-available

# Write the content to the file if it doesn't exist or if user confirms overwrite
if [ ! -f "$backup_file" ] || [ "$overwrite_backup" == "y" ]; then
    echo "$content_backup" > "$backup_file"
    echo "File '$backup_file' created."
else
    echo "File '$backup_file' already exists. Skipped creation."
fi

echo "Don't forget to activate your backup!"

# Ask if you want to create another backup
read -p "Do you want to create another backup? (y/n): " make_another_backup_response

if [ "$make_another_backup_response" == "y" ]; then
    ./choosebackuptype.sh
fi
