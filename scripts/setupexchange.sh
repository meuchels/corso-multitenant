#!/bin/bash

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
export configfile=/opt/corso/toml/${tenantshortname}-exchange.toml
EOF
)

# Create the environments directory if it doesn't exist
mkdir -p ./environments

# Write the content to the file
echo "$content_environment" > "./environments/$SHORT_TENANT_NAME-exchange"

# Provide some feedback
echo "File './environments/$SHORT_TENANT_NAME-exchange' created."

# Define the content of the backup script file
content_backup=$(cat <<EOF
#!/bin/bash

##############Begin Edit###

#change blank to tenant short name
source /opt/corso/scripts/environments/$TENANT_SHORT_NAME-exchange

##############End Edit###


# create runtime variables
logfilename="/opt/corso/log/${tenantshortname}-exchange/$(date +'%Y-%m-%d-%H%M%S').log"
runcorso="/opt/corso/corso"

# init bucket
$runcorso repo init s3 --bucket $bucket --prefix ${tenantshortname}_exchange --endpoint $s3endpoint --log-file $logfilename --config-file $configfile --hide-progress
$runcorso repo connect s3 --bucket $bucket --log-file $logfilename --config-file $configfile --hide-progress

# Run Backup
$runcorso backup create exchange --mailbox '*' --log-file $logfilename --config-file $configfile --hide-progress
EOF
)

# Create the back-available directory if it doesn't exist
mkdir -p ./back-available

# Write the content to the file
echo "$content_backup" > "./back-available/$SHORT_TENANT_NAME-exchange"

# Provide some feedback
echo "File './back-available/$SHORT_TENANT_NAME-exchange' created."

echo "Don't forget to activate your backup!"
