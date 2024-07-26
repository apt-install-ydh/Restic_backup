# Variables
REPO="sftp:Truenas:../Restic/Ubuntu-laptop"
EXCLUDE_FILE="excludes.txt"
BACKUP_DIR="/home/ydh/"
SMTP_CREDENTIALS_FILE="creds.txt"
EMAIL_FROM="email.txt"
EMAIL_TO=""


# Prepare the JSON payload for the SMTP2GO API
#JSON_PAYLOAD=$(printf '{"to":"%s", "from":"%s", "subject":"%s", "text":"%s"}' "$EMAIL_TO" "$SMTP_USER" "$subject" "$EMAIL_CONTENT")

# Send the email using SMTP2GO API
curl --request POST \
     --url https://api.smtp2go.com/v3/email/send \
     --header 'Content-Type: application/json' \
     --header 'X-ssmtp2go-Api: api-key-here' \
     --header 'accept: application/json' \
     --data "$JSON_PAYLOAD"


# Check for errors in the SMTP2GO response
if [[ $? -ne 0 ]]; then
    echo "Error sending email via SMTP2GO"
    exit 1
fi

# Make back up
restic -r $REPO --exclude-file=excludes.txt backup $BACKUP_DIR /home/ydh/ || { send_email "Backup Failed" "Backup failed."; exit 1; }


# Check repo
restic -r $REPO check || { send_email "Repository Check Failed" "Repository check failed."; exit 1; }

# Forget snapshot
restic -r $REPO forget --keep-last 183 || { send_email "Snapshot Management Failed" "Failed to manage snapshots."; exit 1; }

# Delete not referenced snapshots
restic -r $REPO prune || { send_email "Pruning Failed" "Failed to prune unreferenced snapshots."; exit 1; }