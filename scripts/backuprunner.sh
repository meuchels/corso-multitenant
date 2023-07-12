#!/bin/bash

# Directory containing the scripts
script_directory="/opt/corso/scripts/back-active"

# Email configuration
recipient="<YOUR-EMAIL-ADDRESS"
subject_prefix="Backup Job: "

# Iterate over all scripts in the directory
for script_file in "$script_directory"/*; do
    # Run the script and capture the output
    output=$("$script_file")

    # Prepare email subject
    script_name=$(basename "$script_file")
    subject="$subject_prefix$script_name"

    # Send an email with the script output
    echo "$output" | mail -s "$subject" "$recipient"
