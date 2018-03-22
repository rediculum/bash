#!/bin/bash
#
# This scripts adds or removes A and PTR records
# over nsupdate with rndc key
#
# Fri Apr  8 12:41:47 CEST 2011 - hanr
#
 
# Variables
TTL=3600
DNSSERVER="127.0.0.1"
 
KEYFILE=/etc/bind/rndc.key
DNSFILE=`mktemp`
HOSTNAME="$2"
IPADDR="$3"
 
 
# Functions
f_usage(){
        echo "Usage: $0 {add | del} fqdn ip.addr.ess"
        exit 1
}
 
f_extract_key(){
        KEYNAME=`grep ^key $KEYFILE |cut -f2 -d\"`
        SECRET=`grep secret $KEYFILE |cut -f2 -d\"`
}
 
f_check_host(){
        host $1 $DNSSERVER >/dev/null
        if [ $? -eq 0 ]; then
                return 0
        else
                return 1
        fi
}
 
f_add_dns(){
        f_check_host $HOSTNAME && { echo "A record already exists"; exit 1; }
        f_check_host $IPADDR && { echo "PTR record already exists"; exit 1; }     
 
        cat << EOD >$DNSFILE
server $DNSSERVER
update add $HOSTNAME $TTL A $IPADDR
send
EOD
        f_do_nsupdate && echo "Added A record for $HOSTNAME"
 
        cat << EOD >$DNSFILE
server $DNSSERVER
update add $REVIPADDR.in-addr.arpa $TTL PTR ${HOSTNAME}.
send
EOD
        f_do_nsupdate && echo "Added reverse PTR entry for $IPADDR"
}
 
f_del_dns(){
        f_check_host $HOSTNAME || { echo "A record does not exist"; exit 1; }
        f_check_host $IPADDR || { echo "PTR record does not exist"; exit 1; }
 
        cat << EOD >$DNSFILE
server $DNSSERVER
update delete $HOSTNAME A
send
EOD
        f_do_nsupdate && echo "Deleted A record for $HOSTNAME"
 
        cat << EOD >$DNSFILE
server $DNSSERVER
update delete $REVIPADDR.in-addr.arpa IN PTR ${HOSTNAME}.
send
EOD
        f_do_nsupdate && echo "Deleted reverse PTR record for $IPADDR"
}
 
f_do_nsupdate(){
        f_extract_key
        nsupdate -y $KEYNAME:$SECRET $DNSFILE
}
 
# Main
[[ `whoami` == "root" ]] || { echo "Only root can execute this script"; exit 1; }
[[ $# -eq 3 ]] || f_usage
 
# Revert IP address for PTR record
REVIPADDR=`echo $IPADDR |awk -F. '{print $4,$3,$2,$1}' |tr ' ' '.'`
 
case $1 in 
        add)
                f_add_dns
                ;;
        del)
                f_del_dns
                ;;
        *)
                f_usage
                ;;
esac
rm -f $DNSFILE
