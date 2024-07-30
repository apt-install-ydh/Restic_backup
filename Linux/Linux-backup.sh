#!/bin/bash
# Initialize variables
backup_status=""
back_log=""
CHECK_STATUS=""
REPO="sftp:Truenas:../Restic/Ubuntu-laptop"
EXCLUDE_FILE="excludes.txt"
BACKUP_DIR="/home/ydh/"
SMTP_CREDENTIALS_FILE="creds.txt"
EMAIL_FROM="email_from.txt"
EMAIL_TO="email_to.txt"
API_Key="API_Key.txt"
PASSWORD_FILE="repo_password.txt"

# Attempt to create a backup
backup_status=$(restic -r $REPO --password-file $PASSWORD_FILE --exclude-file $EXCLUDE_FILE backup $BACKUP_DIR 2>&1)
backup_log="$backup_status"

# Check if the backup command failed
if [[ $? -ne 0 ]]; then
    EMAIL_SUBJECT="Backup failed"
else
    EMAIL_SUBJECT="Backup Succeeded"
fi

# Snapshot check
CHECK_STATUS=$(restic -r $REPO --password-file $PASSWORD_FILE check)

NO_ERRORS_FOUND=$(echo "$CHECK_STATUS" | grep -i "no errors")

# Status about backup
NEW_ADDED_SIZE=$(echo "$backup_log" | grep -o 'added [0-9]\+' | cut -d' ' -f2)

# Adjusted to handle array output from restic
SNAPSHOT_COUNT=$(restic -r $REPO snapshots --password-file $PASSWORD_FILE --json | jq '.[] | .id' | wc -l)

# Generate email body
EMAIL_BODY="Backup Log:\n$backup_log\n\nNew Added Size: $NEW_ADDED_SIZE bytes\nSnapshot Count: $SNAPSHOT_COUNT \n\nRestic Repo Check Status:\n$NO_ERRORS_FOUND"

JSON_PAYLOAD=$(printf '{"sender":"%s", "to": ["%s"], "subject": "%s", "text_body": "%s"}' "$(cat $EMAIL_FROM)" "$(cat $EMAIL_TO)" "$EMAIL_SUBJECT" "$EMAIL_BODY" | sed ':a;N;$!ba;s/\n/\\n/g')

# Send the email using SMTP2GO API
curl --request POST \
     --url https://api.smtp2go.com/v3/email/send \
     --header 'Content-Type: application/json' \
     --header "X-Smtp2go-Api-Key: $(cat $API_Key)" \
     --header 'accept: application/json' \
     --data "$JSON_PAYLOAD"