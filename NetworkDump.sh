#This is a simple bash script which gathers information on the local networking stack of a Linux server.
# Note that this requires net-tools to be installed.

#!/bin/bash
# Instructions:
# Simply run the script, and the output will be saved to the current folder as NetworkInfo_[date].txt
#Get the current date
date=$(date +"%Y-%m-%d")
#Set the file name for output
filename="NetworkInfo_${date}.txt"
#Get hostname
server=$(hostname)
echo "Gathering network info.."
#Output info to file
echo "Network Information Report = $server" > $filename
echo "_____________________________________________" >> $filename
# Get IP address info
echo "IP Addresses:" >> $filename
ip addr show  >> $filename
echo "" >> $filename
# Get DNS server info
echo "DNS Servers:" >> $filename
cat /etc/resolv.conf | grep "nameserver" >> $filename
echo "" >> $filename
# Get open ports
echo "Listening Ports:" >> $filename
ss -tuln >> $filename
echo "" >> $filename
# Get route table
echo "Route table:" >> $filename
route -n  >> $filename
echo "" >> $filename
# Get network interfaces
echo "Network Interfaces:" >> $filename
ip link show  >> $filename
echo "" >> $filename
echo "Network information has been saved to $filename"
