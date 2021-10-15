#!/bin/bash
# This script will check current WAN ip address with dig
# and request DNS record change from Namecheap using curl.
# For usage info, run the script without any arguments.
# Written by Sigge Smelror (C) 2021, GNU GPL v. 3+
#
# dyndns.sh is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, version 3 or newer.
#
# dyndns.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# URL: <https://www.gnu.org/licenses/gpl-3.0.txt>
#
# Submit bugs at: <https://github.com/sigg3/namecheap_dyndns/issues>


USAGE=$(basename "$0")
USAGE="$USAGE <subdomain> <domain> <password | FILE> [verbose]

How to update:
  * TLD:       $USAGE @ domain.ext mydyndnspassword
  * subdomain  $USAGE subdomain domain.ext mydyndnspassword
  * wildcard   $USAGE * domain.ext ~/.conf/ncheap_dns_pass

Password field required. It can be either a string or full path
to a file containing the password (safer). Note: This is not your
Namecheap user account password, but the Dynamic DNS password.

$USAGE will only request DNS record change if WAN ip has changed.
Use -v flag or a 1 as the last arg to run verbosely."

# Parse CLI args
[ -z "$1" ] && { echo "$USAGE" ; exit ;} || N_SUBDOMAIN="$1"
[ -z "$2" ] && { echo "$USAGE" ; exit ;} || N_DOMAIN="$2"
[ -z "$3" ] && { echo "$USAGE" ; exit ;} || N_PASSWORD="$3"
[ -n "$4" ] && VERBOSE="1" || VERBOSE="0"

# Check curl requirement
if ! command -v curl >> /dev/null ; then
        echo "Sorry, no curl in PATH" ; exit 1
fi

# Set history file
IP_HIST="$HOME/.wan_ip_log"

# Read password if the supplied arg is a file
if [ -f "$N_PASSWORD" ] ; then
	N_PASSWORD=$( tail -n 1 "$N_PASSWORD" | tr -d "\r\n ")
fi

# SETTINGS (uncomment for debugging)
#cat <<EOT
#N_DOMAIN    = $N_DOMAIN
#N_SUBDOMAIN = $N_SUBDOMAIN
#N_PASSWORD  = $N_PASSWORD
#VERBOSE     = $VERBOSE
#IP_HIST     = $IP_HIST
#EOT
#exit

# Check curl requirement
if ! command -v curl >> /dev/null ; then
	echo "Sorry, no curl in PATH" ; exit 1
fi

# Check connectivity
if ! ping -c 1 opendns.com >> /dev/null ; then
	echo "Can't reach OpenDNS resolver. No internet?" ; exit 1
fi

# Get old and current WAN IP address
[ ! -f "$IP_HIST" ] && touch "$IP_HIST"
NEW_IP=$( dig +short myip.opendns.com @resolver1.opendns.com | tr -d "\n " )
OLD_IP=$( awk -F";" 'END{print $NF}' "$IP_HIST" | tr -d "\n " )

# Check for any change in IP
if [ "$NEW_IP" == "$OLD_IP" ] ; then
	echo "WAN IP unchanged ($NEW_IP)" ; exit 0
fi

# WAN ip has changed! Log the new one:
echo "WAN IP has changed from $OLD_IP to $NEW_IP"
echo "$(date '+%Y-%m-%d %H:%M');$NEW_IP" >> "$IP_HIST"

# Create DNS change HTTPS request for NAMECHEAP

# Set hostname
[ -n "$N_SUBDOMAIN" ] && N_HOST="$N_SUBDOMAIN" || N_HOST="@"

# Create HTTPS request
N_UPDATE="https://dynamicdns.park-your-domain.com/update"
N_UPDATE+="?" ; N_UPDATE+="host=$N_HOST"
N_UPDATE+="&" ; N_UPDATE+="domain=$N_DOMAIN"
N_UPDATE+="&" ; N_UPDATE+="password=$N_PASSWORD"
N_UPDATE+="&" : N_UPDATE+="ip=$NEW_IP"

# Send HTTPS request
SENDING="Sending DNS update request to Namecheap .. "
if [ "$VERBOSE" -eq "1" ] ; then
	echo -e "$SENDING\n\n" ; curl -i -v "$N_UPDATE"
else
	echo -n "$SENDING" ; curl -s "$N_UPDATE" >> /dev/null
fi

CURL_ERR="$?"
case "$CURL_ERR" in
0 ) ERR_MSG="" ;;
1 ) ERR_MSG="This build of curl does not support https" ;;
3 ) ERR_MSG="Malformed URL. Wrong syntax." ;;
4 ) ERR_MSG="Requirement missing. You need a different libcurl." ;;
6 ) ERR_MSG="Can't resolve host." ;;
7 ) ERR_MSG="Can't connect to host." ;;
* ) ERR_MSG="DNS update request failed (curl exit $CURL_ERR)" ;;
esac

# There were errors. Exit using curl exit code
[ -n "$ERR_MSG" ] && { echo -e "\n\n$ERR_MSG" ; exit $CURL_ERR ; }

# No errors
[ "$VERBOSE" -eq "1" ] && echo -e "\n\n" ; echo "Done."
exit 0
