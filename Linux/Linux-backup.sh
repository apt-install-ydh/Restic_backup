# make back up
restic -r sftp:Truenas:../Restic/Ubuntu-laptop --verbose --exclude-file=excludes.txt backup --no-scan /home/ydh/

# check repo
restic -r sftp:Truenas:../Restic/Ubuntu-laptop check