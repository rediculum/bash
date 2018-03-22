#!/bin/bash
#
# Tue May  5 12:25:41 CEST 2009 / hanr
# Thu Jul 16 10:38:10 CEST 2009 / hanr - added verbose info
# Tue Oct  6 09:45:01 CEST 2009 / hanr - added devfsadm and cfgadm
# Wed Jan 27 14:46:35 CEST 2010 / hanr - checks also local filesystems
#                                        and looks in vfstab if not in metadb
# Wed Jun  9 12:54:20 CEST 2010 / hanr - added metadb check and warning if in vfstab
#                                        fixed some stuff and made it functional
# Fri Jun 10 09:17:06 CEST 2011 / hanr - added version, minor bugfix
#
# This script compares disks from format in metadb and vice versa
# Must run under root and SunOS
#
 
VERSION=0906610
 
f_checks() {
        if [ `id |cut -f2 -d'=' |cut -f1 -d'('` -ne "0" ]; then
                echo "This script must run under UID 0 (root)"
                exit 2
        fi
        if [[ `uname -s` -ne "SunOS" ]]; then
                echo "This script runs only on Solaris"
                exit 2
        fi
 
        if [[ ! `metadb` ]]; then
                echo "No metadb found on this machine. Seems you don't use the Solaris LVM"
                exit 2
        fi
}
 
f_parameters() {
        case $1 in
                -v)
                        VERBOSE=1
                        ;;       
                -h|--help)
                        echo "Usage: $0 [-v]"
                        exit 1               
                        ;;    
                *)        
                        VERBOSE=0
        esac
}
 
f_device_discovery() {
        printf "Device discovery..."
        printf "devfsadm...."
        devfsadm -C
        printf "cfgadm..."
        cfgadm -al > /dev/null
        echo "done"
        printf "\n\n"
}
 
f_compare_format2metadb() {
        METADB=`metastat -c`
        echo " COMPARE IF DISK FROM FORMAT IS IN METADB "
        echo "------------------------------------------------------"
        for DISK in `format </dev/null |grep alt |grep -v configured |awk '{print $2}'`; do
                printf "Searching Disk $DISK in metadb: "
                if [[ `echo $METADB |grep $DISK` ]]; then
                        echo -e "\033[1mok\033[0m"
                else
                        if [[ `grep $DISK /etc/vfstab` ]]; then
                                echo -e "not found, but in vfstab. \033[1mwarning\033[0m"
                        else
                                echo "NOT IN METADB FOUND!!!"
                        fi
                fi
                if [ "$VERBOSE" -eq "1" ]; then
                        format $DISK <<EOF |tail -12
ver
q
EOF
                echo "> > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > >"
                echo ""
                fi     
        done
        #echo "Press ENTER key to continue..."; read
        printf \\n\\n
}
 
f_compare_metadb2format() {
        FORMATLIST=`format </dev/null`
        echo " COMPARE IF DISK FROM METADB IS IN FORMAT "
        echo "------------------------------------------------------"
        for DISK in `metastat -c |grep dsk |awk '{print $4}' |cut -f4 -d'/' |cut -f1 -d's'`; do
                printf "Searching Disk $DISK in format: "
                if [[ `echo $FORMATLIST |grep $DISK` ]]; then
                        echo -e "\033[1mok\033[0m"
                else
                        echo "NOT IN FORMAT FOUND !!!"
                fi
        done
}
 
# MAIN
printf "\n*** `basename $0` - Version $VERSION *** \n\n"
f_checks
f_parameters $1
f_device_discovery
f_compare_format2metadb
f_compare_metadb2format
