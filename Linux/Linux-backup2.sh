# Initialize variables
backup_status=""
back_log=""
REPO="sftp:Truenas:../Restic/Ubuntu-laptop"
EXCLUDE_FILE="excludes.txt"
BACKUP_DIR="/home/ydh/"
SMTP_CREDENTIALS_FILE="creds.txt"
EMAIL_FROM="email_from.txt"
EMAIL_TO="email_to"

# Attempt to create a backup
backup_status=$(restic -r $REPO --exclude-file$EXCLUDE_FILE backup $BACKUP_DIR 2>&1)
backup_log="$backup_status"

# check if the backup command failed
if [[ $? -ne 0 ]]; then
    # set the email subject to indicate fail
    EMAIL_SUBJECT="Backup failed"

else
    # set the email subject to indicate success
    EMAIL_SUBJECT="Backup Succeeded"

fi

# status about back up
NEW_ADDED_SIZE=$(echo "$backup_log" | grep -oP 'added \k\d+ bytes')
TOTAL_REPO_SIZE=$(restic -r $REPO size --json | jq '.size')
SNAPSHOT_COUNT=$(restic -r $REPO snapshots --json | jq '.snapshots | length')

# generate email body
EMAIL_BODY="Backup Log:\n$backup_log\n\nNew Added Size: $NEW_ADDED_SIZE bytes\nTotal Repo Size: $TOTAL_REPO_SIZE bytes\nSnapshot Count: $SNAPSHOT_COUNT"


## Send email
# generate JSON payload for the SMTP2GO API
JSON_PAYLOAD=$(printf '{"sender":"%s", "to": ["%s"], "subject": "%s", "text_body": "%s"}' "$(cat $EMAIL_FROM)" "$EMAIL_TO" "$EMAIL_SUBJECT" "$EMAIL_BODY")

# Send the email using SMTP2GO API
curl --request POST \
     --url https://api.smtp2go.com/v3/email/send \
     --header 'Content-Type: application/json' \
     --header 'X-ssmtp2go-Api: api-key-here' \
     --header 'accept: application/json' \
     --data "$JSON_PAYLOAD"
