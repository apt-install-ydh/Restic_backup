#!/bin/bash

# Variables
REPO="sftp:Truenas:../Restic/Ubuntu-laptop"
EXCLUDE_FILE="excludes.txt"
BACKUP_DIR="/home/ydh/"

# Function to send email
send_email() {
    local subject="$1"
    local body="$2"
    echo "$body" | mail -s "$subject" your_email@example.com
}

# Make back up
restic -r $REPO --exclude-file=$EXCLUDE_FILE backup $BACKUP_DIR || { send_email "Backup Failed" "Backup failed."; exit 1; }

# Check repo
restic -r $REPO check || { send_email "Repository Check Failed" "Repository check failed."; exit 1; }

# Forget snapshot
restic -r $REPO forget --keep-last 183 || { send_email "Snapshot Management Failed" "Failed to manage snapshots."; exit 1; }

# Prune unreferenced snapshots
restic -r $REPO prune || { send_email "Pruning Failed" "Failed to prune unreferenced snapshots."; exit 1; }

# Send success email
send_email "Backup Succeeded" "Backup succeeded. All operations completed successfully."
