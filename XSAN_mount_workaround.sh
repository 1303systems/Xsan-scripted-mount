#!/bin/sh

# This script manually mounts an XSAN volume when unable to mount with 'xsanctl'
# This is a workaround for a bug introduced in MacOS 12.7.2+, 13.6.2+ 14.2+

xsan_logging_directory="/Library/Logs/Xsan/debug/"
latest_log=$(ls -1 $xsan_logging_directory | grep '^mount-debug\.[0-9]\+$' | sort -t. -k2 -n | tail -n 1)
xsan_mount_error="Unrecognized option: 'owners'"
mount_point="/Volumes/QSAN"

echo "Latest log is $latest_log"

# Check if any log files were found
if [ -n "$latest_log" ]; then
    # Checks for mount error in $latest_log without spamming the entire log file :)
    if grep -q "$xsan_mount_error" "$xsan_logging_directory/$latest_log"; then
        # Checks the XSAN disk in $latest_log and stores it as a variable
        # This line is dumb as ****
        xsan_disk=$(cat $xsan_logging_directory/$latest_log | grep "find_IORegistryBSDName: searching for" | awk -F'[<>]' '{print $2}')
        # Create a mount point
        echo "Creating empty directory at $mount_point"
        mkdir $mount_point
        # I know, I'm a monster. Just ignore this part. It's only temporary.
        echo "Modifying permissions"
        sudo chmod 777 /Volumes/Mount
        # Manually mounts the XSAN disk
        echo "Manually mounting /dev/$xsan_disk > $mount_point"
        /System/Library/Filesystems/acfs.fs/Contents/bin/mount_acfs -o rw -o nofollow /dev/$xsan_disk $mount_point
        if [ $? -eq 0 ]; then
            echo "Succesfully connected to $mount_point"
        else
            echo "Failed to connect to $mount_point"
        fi
    else
        echo "No mount error found in $xsan_logging_directory/$latest_log. Is XSAN service running?"
    fi
else
    echo "No log files found in $xsan_logging_directory. Is XSAN service running?"
fi