#!/bin/bash

# Locations to monitor (array)
monitorDirs=("/root" "/etc" "/var/log")

# Log file
date=$(date +"%Y-%m-%d")
logFile="/usr/scripts/output/changeLog_${date}.log"

# Create Function to monitor the changes

changeMonitor() {
  for directory in "${monitorDirs[@]}"; do
    find "$directory" -type f \( -name ".*" -o -perm -4000 \) -exec stat --format '%n %y %U' {} + 
  done
}

# Check if the log file exists, if not run now.
if [ ! -f "$logFile" ]; then
  echo "Initial log does not exist, running now.."
  changeMonitor > "$logFile"
fi

# Check for changes
tempLog="/usr/scripts/output/changeLogTemp.log"
changeMonitor > "$tempLog"

if ! cmp -s "$logFile" "$tempLog"; then
  echo "Changes found!"
  diff "$logFile" "$tempLog"
  # copy the new values to the existing log file
  mv "$templog" "$logFile"
else
  echo "Nothing Found..."
  # Remove the temp log file
  rm "$templog" -f
fi
