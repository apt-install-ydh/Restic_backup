# Initialize variables
$backup_status = ""
$log = ""
$check_status = ""
$repo = "sftp:Truenas:../Restic/Ubuntu-laptop"
$exclude_file = "excludes.txt"
$backup_dir = "C:\Users\dirk"
$smtp_credentials_file = "creds.txt"
$email_from = Get-Content "email_from.txt"
$email_to = Get-Content "email_to.txt"
$api_key = Get-Content "API_Key.txt"
$password_file = "repo_password.txt"

# Attempt to create a backup
$backup_status = restic -r $repo --password-file $password_file --exclude-file $exclude_file backup $backup_dir 2>&1
$log = $backup_status

# Check if the backup command failed
if ($LASTEXITCODE -ne 0) {
    $email_subject = "Backup failed"
} else {
    $email_subject = "Backup Succeeded"
}

# Retention policy for snapshots
restic -r $repo --password-file $password_file forget --keep-daily 3 --keep-weekly 4 --keep-monthly 3 --keep-yearly 1 --prune

# Snapshot check
$check_status = restic -r $repo --password-file $password_file check

$no_errors_found = $check_status | Select-String -Pattern "no errors" -Quiet

$new_added_size = $log | Select-String -Pattern 'added [0-9]+' | ForEach-Object { $_.Matches[0].Value.Split(' ')[1] }

$snapshot_count = (restic -r $repo snapshots --password-file $password_file --json | ConvertFrom-Json).id.Count

# Generate email body
$email_body = "Backup Log:`n$log`n`nNew Added Size: $new_added_size bytes`nSnapshot Count: $snapshot_count `n`nRestic Repo Check Status:`n$no_errors_found"

$json_payload = @{
    sender = Get-Content $email_from
    to = @((Get-Content $email_to))
    subject = $email_subject
    text_body = $email_body
} | ConvertTo-Json

# Send the email using SMTP2GO API
Invoke-RestMethod -Uri "https://api.smtp2go.com/v3/email/send" -Method Post -ContentType "application/json" -Headers @{ "X-Smtp2go-Api-Key" = $api_key; "accept" = "application/json" } -Body $json_payload
