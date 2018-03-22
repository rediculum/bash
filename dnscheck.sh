#!/bin/bash
#
# Compare DynDNS Hostname with A Record Entry asked on /etc/resolv.conf servers
#
# Thu Feb  7 01:41:14 CET 2008
# Wed May 21 10:59:33 CEST 2008 / Added abort (exit 1) if no internet connection
# Mon Aug 11 16:49:21 CEST 2008 / Added flag to reduce mail notifications
#
# Variables
EMAIL="hanr"               # separate with semicolons
FROM="ipcheck"
SYSLOG=/var/log/messages
FLAG=/tmp/dnscheck.flag
DYNDNS=`ping -c 1 runlevel.dyndns.org |head -1 |awk '{print $3}' |tr "(|)" " "`
FIXDNS=`ping -c 1 runlevel.ch |head -1 |awk '{print $3}' |tr "(|)" " "`
 
# Script
if [ "$DYNDNS" = "" ]; then
        echo `date "+%b %e %H:%M:%S"` `hostname -f` "Warn: dnscheck.sh could not resolve hostnames" >>$SYSLOG
        exit 1
fi
if [ $DYNDNS != $FIXDNS ]; then
        if [ -t $FLAG ]; then
                echo `date "+%b %e %H:%M:%S"` `hostname -f` "Warn: Public IP has changed from $FIXDNS to $DYNDNS" >>$SYSLOG
                exit 1
        else
                touch $FLAG
        fi
        echo "Change DNS entries at www.mydomain.com and dislist $DYNDNS on spamhaus" | mailx -a from:$FROM -s "Public IP has changed from $FIXDNS to $DYNDNS" $EMAIL
        echo `date "+%b %e %H:%M:%S"` `hostname -f` "Warn: Public IP has changed from $FIXDNS to $DYNDNS" >>$SYSLOG
        exit 1
else
        echo `date "+%b %e %H:%M:%S"` `hostname -f` "Public IP is still $FIXDNS" >>$SYSLOG
        if [ -f $FLAG ]; then
                rm -f $FLAG
        fi
        exit 0
fi
 
# EOF
