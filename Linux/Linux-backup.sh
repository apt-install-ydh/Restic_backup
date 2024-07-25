# Make back up
restic -r sftp:Truenas:../Restic/Ubuntu-laptop --exclude-file=excludes.txt backup --no-scan /home/ydh/

# Check repo
restic -r sftp:Truenas:../Restic/Ubuntu-laptop check

# Forget snapshot
restic -r sftp:Truenas:../Restic/Ubuntu-laptop forget --keep-last 183

# Delete not referenced snapshots
restic -r sftp:Truenas:../Restic/Ubuntu-laptop prune