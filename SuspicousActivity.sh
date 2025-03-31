!/bin/bash

# Get the current date
date=$(date +"%Y-%m-%d")

# Set the file name for output
filename="/usr/scripts/output/suspiciouslogins_${date}.txt"
mkdir -p /usr/scripts/output/

# Define the user to monitor (in this case the Local Administrator on the machine)
user="Admin"

# Set suspicous hours range
targetHourStart=0
targetHourEnd=6

# Use awk to scrape the log file for entries
awk -v user="$user" -v start="$targetHourStart" -v end="$targetHourEnd" '
 {
   # convert the timestamp field to hours in order to use the target start and end timeframe   
   split($1, datetime, "T");
   split(datetime[2], time, ":");
   hour = time[1];
   entry = $12;
   log_user = $4;

   if (hour >= start && hour < end || log_user == user) {print $1, $4, $12}
 }
 ' "/var/log/auth.log" > $filename
