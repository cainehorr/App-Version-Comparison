#!/bin/bash

##############################################################################
#
# SCRIPT FILENAME:
# 	AppVersionComparison.sh
#
# DESCRIPTION:
#	Use for comparparing an existing installed application version number to 
#	that of the required version number then take action using a Jamf Pro 
#	workflow.
#
# USEAGE:
#	Designed to be run in one of three user configurable modes
#		* Command Line Run Mode
#		* Jamf Pro Simulation Run Mode
#		* Jamf Pro Run Mode
#
# CHANGE LOG:
#	v1.0 - 2020-03-12
#		Written by Caine Hörr
#		https://github.com/cainehorr
#			* Initial Script Creation
#
##############################################################################

##############################################################################
#
# MIT License
#
# Copyright (c) 2020 Caine Hörr
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to 
# deal in the Software without restriction, including without limitation the 
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
##############################################################################

##############################################################################
#
# CHOOSE YOUR RUN MODE
#	DO NOT REARRANGE THE ORDER IN WHICH THESE VARIABLES APPEAR
#		Comment/Uncomment accordingly...
#
# runMode="Jamf Pro"
# runMode="Jamf Pro Simulation"
# runMode="Command Line"
#
##############################################################################

##############################################################################
#
# THERE ARE NO USER SERVICABLE PARTS DOWN HERE...
# DO NOT EDIT BELOW THIS LINE!
#
##############################################################################

if [ "${runMode}" == "Command Line" ] && [ "${runMode}" != "Jamf Pro" ] && [ "${runMode}" != "Jamf Pro Simulation" ]; then
	## Run Mode: Command Line
	echo "${0} configured for ${runMode} Run Mode"
	appName="$(/bin/echo ${1})"		
	requiredVersion="$(/bin/echo ${2})"

	# Confirm the existance of the command line arguments
	if [ -z "${appName}" ] || [ -z "${requiredVersion}" ]; then
		echo ""
		echo "ERROR: Missing Arguments"
		echo ""
		echo "REQUIRED SYNTAX: sudo ${0} [Application Name] [Required Application Version]"
		echo ""
		echo "    EXAMPLES:"
		echo "        sudo ${0} \"Google Chrome.app\" \"80.0.3987.132\"" 
		echo "        sudo ${0} \"zoom.us.app\" \"4.6.4\"" 
		echo ""
		exit 1
	fi
elif [ "${runMode}" != "Command Line" ] && [ "${runMode}" == "Jamf Pro" ] && [ "${runMode}" != "Jamf Pro Simulation" ]; then
	# Run Mode: Jamf Pro
	echo "${0} configured for ${runMode} Run Mode"
	appName="$(/bin/echo ${4})"	
	requiredVersion="$(/bin/echo ${5})"
	customTrigger="$(/bin/echo ${6})"
	if [ -z "${appName}" ] || [ -z "${requiredVersion}" ] || [ -z "${customTrigger}" ]; then
		echo ""
		echo "ERROR: Missing Jamf Pro Script Paramaters"
		echo ""
    	echo "SCRIPT INFO: Jamf Pro > Settings > Computer Management > Script > Options > Parameters 4, 5, and 6"
    	echo "POLICY INFO: Jamf Pro > Computers > Policies > \"Policy Name\" > Options > Scripts > AppVersionComparison.sh > Paramater Values (4, 5 and 6)"
    	echo ""
		echo "REQUIRED: Paramater 4 [Application Name]"
		echo "REQUIRED: Paramater 5 [Required Application Version]"
		echo "REQUIRED: Paramater 6 [Custom Jamf Policy Trigger]"
		echo ""
		exit 1
	fi
elif [ "${runMode}" != "Command Line" ] && [ "${runMode}" != "Jamf Pro" ] && [ "${runMode}" == "Jamf Pro Simulation" ]; then
	# Run Mode: Jamf Pro Simulation
	echo "${0} configured for ${runMode} Run Mode"
	appName="$(/bin/echo ${1})"		
	requiredVersion="$(/bin/echo ${2})"
	customTrigger="$(/bin/echo ${3})"

	# Confirm the existance of the command line arguments
	if [ -z "${appName}" ] || [ -z "${requiredVersion}" ] || [ -z "${customTrigger}" ]; then
		echo ""
		echo "ERROR: Missing Arguments"
		echo ""
		echo "REQUIRED SYNTAX: sudo ${0} [Application Name] [Required Application Version] [Custom Jamf Policy Trigger]"
		echo ""
		echo "    EXAMPLES:"
		echo "        sudo ${0} \"Google Chrome.app\" \"80.0.3987.132\" \"google_chrome_upgrade\"" 
		echo "        sudo ${0} \"zoom.us.app\" \"4.6.4\" \"zoom_us_upgrade\"" 
		echo ""
		exit 1
	fi
else
	echo "ERROR: Invalid Run Mode"
	echo "INFO: Please configure the proper Run Mode by editing ${0}"
	exit 1
fi



main(){
	Run_as_Root
	Identify_Jamf_Binary
	App_Validation
	App_Version_Checker
}

Run_as_Root(){
    # Check for admin/root permissions
    if [ "$(id -u)" != "0" ]; then
    	echo ""
        echo "ERROR: Script must be run as root or with sudo."
        echo ""
        exit 1
    fi
}

Identify_Jamf_Binary(){
	jamf_binary="$(/usr/bin/which jamf)"

	if [ -f "${jamf_binary}" ]; then
		echo "INFO: Jamf binary installed at ${jamf_binary}"
	else
		echo "ERROR: Jamf binary not found!"
		exit 1
	fi
}

App_Validation(){
	appName="/Applications/${appName}"

	if [ ! -d "${appName}" ]; then
		echo "[ERROR] ${appName} not installed"
		exit 1
	fi
}

App_Version_Checker(){
	echo "[INFO]: Application Name: ${appName}"
	echo "[INFO]: Required Version: ${requiredVersion}"
	requiredVersion="$(echo ${requiredVersion} | tr -d '.')"

	currentAppVersion="$(defaults read "${appName}/Contents/Info" CFBundleShortVersionString | awk '{ print $1 }')"
	echo "[INFO]: Current Version: ${currentAppVersion}"
	currentAppVersion="$(echo ${currentAppVersion} | tr -d '.')"

	if [[ ${currentAppVersion} -ge ${requiredVersion} ]]; then
		echo "[INFO]: The currently installed version of ${appName} is the same or newer than the required version."

		if [ "${runMode}" == "Jamf" ]; then
			sudo ${jamf_binary} recon -verbose
		elif [ "${runMode}" == "Jamf Pro Simulation" ]; then
			echo "[SIMULATION MODE]: sudo ${jamf_binary} recon -verbose"
		fi
	else
		echo "[WARNING]: The currently installed version of ${appName} is older than the required version."
		if [ "${runMode}" == "Jamf" ]; then
			sudo ${jamf_binary} policy -event ${customTrigger} -verbose
		elif [ "${runMode}" == "Jamf Pro Simulation" ]; then
			echo "[SIMULATION MODE]: sudo ${jamf_binary} policy -event ${customTrigger} -verbose"
		fi
	fi
}

main

exit