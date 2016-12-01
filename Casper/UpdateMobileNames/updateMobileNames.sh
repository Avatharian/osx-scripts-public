#!/bin/sh

# Name: updateMobileNames.sh
# Date: 1 December, 2016
# Based on updateAssetTags.sh by Steve Wood (swood@integer.com)
# Author: Jason Caudle (jason@caudle.io)
# Purpose: used to read in device name data from a CSV file and update the record in the JSS
# This script is written for updating a mobile device in the JSS but can be altered for a computer
# by simply changing the <mobile_device> and </mobile_device> tags to <computer> and </computer>
# API will also enable "Enforce Mobile Device Name" for modified device entries
#
# The CSV file needs to be saved as a UNIX file with LF, not CR
# in the format of "serialnumber,devicename"
#
# Version: 1.0 - Basic functionality
# Possible future changes: Combine asset tag functionality and command line switch to choose what to update
#
# A good portion of this script is re-purposed from the script posted in the following JAMF Nation article:
#
#  https://jamfnation.jamfsoftware.com/discussion.html?id=13118#respond
#

jssAPIUsername="<apiuser>"
jssAPIPassword="<apipassword>"
jssAddress="https://your.jss.com:8443"
file="$1"

#Verify we can read the file
data=`cat $file`
if [[ "$data" == "" ]]; then
	echo "Unable to read the file path specified"
	echo "Ensure there are no spaces and that the path is correct"
	exit 1
fi

#Find how many computers to import
computerqty=`awk -F, 'END {printf "%s\n", NR}' $file`
echo "Computerqty= " $computerqty
#Set a counter for the loop
counter="0"

duplicates=[]

id=$((id+1))

#Loop through the CSV and submit data to the API
while [ $counter -lt $computerqty ]
do
	counter=$[$counter+1]
	line=`echo "$data" | head -n $counter | tail -n 1`
	serialNumber=`echo "$line" | awk -F , '{print $1}'`
	deviceName=`echo "$line" | awk -F , '{print $2}'`
	
	echo "Attempting to update data for $serialNumber"
	
	echo $serialNumber " " $deviceName
	response=`curl -sS -k -i -u $jssAPIUsername:$jssAPIPassword $jssAddress/JSSResource/mobiledevices/serialnumber/$serialNumber`
	deviceID=`echo $response | xpath '//general/id' 2>&1 | awk -F'<id>|</id>' '{print $2}'`
	output=`curl -sS -k -i -u $jssAPIUsername:$jssAPIPassword -X POST ${jssAddress}/JSSResource/mobiledevicecommands/command/DeviceName/$deviceName/id/$deviceID`
	#Error Checking
	error=""
	error=`echo $output | grep "Conflict"`
	if [[ $error != "" ]]; then
		duplicates+=($serialnumber)
	fi
	#Increment the ID variable for the next user
	id=$((id+1))
done

echo "The following mobile devices could not be updated:"
printf -- '%s\n' "${duplicates[@]}"

exit 0
