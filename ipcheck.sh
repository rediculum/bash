#!/bin/bash
#
# Check if IP has changed and send mail
#
# Mon Feb  2 13:57:44 CET 2009 hanr
# Thu Jul  2 08:33:55 CET 2009 hanr - Send email only if ip is listed on spamhaus
# Mon Jan  4 11:17:07 CET 2010 hanr - Some fixes
#
# Variables
EMAIL="hanr"    # Separate with semicolon
FROM="IP Check <root@runlevel.ch>"
CACHEDADDRESS="/var/tmp/ipcheck.address"
IPADDRESS=`w3m checkip.dyndns.org |awk '{print $4}'`
SPAMHAUSTEXT=
 
# Script
if [ "$IPADDRESS" = "" ]; then
        logger "$0 could not get dyndns.org"
        exit 1
elif [ "$IPADDRESS" != "`cat $CACHEDADDRESS`" ]; then
        SPAMHAUSIP=`w3m http://www.spamhaus.org/query/bl?ip=$IPADDRESS |grep records |awk '{print $3}'` 
        if [ "$SPAMHAUSIP" ]; then      
                printf "Dislist $SPAMHAUSIP on spamhaus \nhttp://www.spamhaus.org/pbl/removal/form" | mailx -a from:"$
FROM" -s "Public IP has changed from `cat $CACHEDADDRESS` to $IPADDRESS" $EMAIL
        fi
        logger "Public IP has changed from `cat $CACHEDADDRESS` to $IPADDRESS"
        echo $IPADDRESS > $CACHEDADDRESS
        exit 1
fi
exit 0
