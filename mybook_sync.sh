#!/bin/bash
#
# SYNCRONISATION SCRIPT FOR MYBOOKS
#
# Usage: mybook_sync.sh [-n]
#
# Tue Feb 24 14:12:14 CET 2009
# Tue Mar 16 10:05:49 CET 2010 Optimized and fixed
 
### Config
RSYNCPARAMS="-aHvh --delete"
TMPFILE="/tmp/mybook_sync.sh.tmp"               # Complete path with filename for mail content
EMAIL="hanr"            # Address where content or alert shoult be sent, semicolon sep.
FROM="mybook-sync"
MYBOOK="/mybook"                                
MIRROR="/mybook_mirror"
TIMESTART=`date +%s`
DRYRUN=
 
### Functions
f_sendmail() {
        if [ "$DRYRUN" ]; then
                cat $TMPFILE
        else
                cat $TMPFILE |mailx -a from:$FROM -s "MyBook Syncronization" $EMAIL  # Send mail with content of file
        fi
        exit 0
}
f_checkbook() {
        if [[ -z `mount |grep "$1 "` ]]; then
                echo "!!! Skipped MyBook Syncronization!! $1 not mounted" >>$TMPFILE
                f_sendmail
        fi
}
### SCRIPT
echo "++++++++++++++++++++++ MyBook sync start at `date +"%H:%M:%S"` +++++++++++++++++++++++" >$TMPFILE
 
if [ "$1" == "-n" ]; then
        RSYNCPARAMS="$RSYNCPARAMS -n"; DRYRUN=1
        echo "RUNNING IN DRY MODE"
fi
 
# Check if MyBooks are mounted
f_checkbook $MYBOOK
f_checkbook $MIRROR
 
# Do the sync
rsync $RSYNCPARAMS $MYBOOK/ $MIRROR >> $TMPFILE
printf "\n\n++++++++++++++++++++++ MyBook sync end at `date +"%H:%M:%S"` +++++++++++++++++++++++" >>$TMPFILE
TIMESTOP=`date +%s`
printf "\n++++++++++++++++++++++++++ Duration `expr $TIMESTOP - $TIMESTART`sec +++++++++++++++++++++++++++" >>$TMPFILE
f_sendmail
