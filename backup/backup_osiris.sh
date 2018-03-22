#!/bin/bash
#
# BACKUP SCRIPT
#
# Usage: backup_osiris.sh [-n]
#
# Fri Aug 20 16:19:26 CEST 2010 - adapted from backup_server.sh and reduced
# Fri Dec  3 10:16:07 CET 2010 / Added retention for increments
#                                Include library for common variables and functions
# Sat Jul  2 14:17:11 CET 2011 - Added keychain requirement
# Fri Aug 19 18:20:56 CET 2011 / Added package list file into /root
 
 
### Config
FOLDERS="/var/log /etc /root"    # Separate with spaces
BACKUPSERVER="server.runlevel.ch"
BACKUPDIR="/mybook/backup/osiris"
TIMESTART=`date +%s`
 
# Source library
. backup.lib.sh || { echo "backup.lib.sh not found"; exit 1; }
 
### Checks
if [ "$1" == "-n" ]; then
        DRYRUN=1
        RDIFFPARAMS="--compare"
        echo "RUNNING IN DRY MODE"
fi
 
# Check if rdiff-backup exists
[[ `which $RDIFFBIN` ]] || { echo "$RDIFFBIN not found"; exit 1; }
 
# Check if a keychain with an adequate ssh agent exist and load it
f_keychain
 
# Check if remote server is reachable and backup dir is available
[[ `$RDIFFBIN --test-server $BACKUPSERVER::$BACKUPDIR >$TMPFILE 2>&1` ]] && { f_error "$BACKUPSERVER not reachable"
; }
[[ `ssh -q $BACKUPSERVER "cd $BACKUPDIR" >$TMPFILE 2>&1` ]] && { f_error "$BACKUPDIR on $BACKUPSERVER not reachable
"; }
 
### Main
printf "++++++++++++++++++++++ Backup Start at `date +"%H:%M:%S"` +++++++++++++++++++++++\n" >>$TMPFILE
 
PKGLIST=/root/packages.installed
DISTRO=`lsb_release -i |awk '{print $3}'`
printf "Creating installed packages list $PKGLIST" >>$TMPFILE
case $DISTRO in
   Debian)
      dpkg --get-selections |grep install |awk '{print $1}' >$PKGLIST
   ;;
   RedHatEnterpriseServer)
      rpm -qa >$PKGLIST
   ;;
   *)
      echo "Could not determine Linux distribution. Skipping package list..." >>$TMPFILE
   ;; 
esac
 
# Building include list
for FOLDER in $FOLDERS; do
        INCLUDEFOLDERS="$INCLUDEFOLDERS --include $FOLDER "
done
 
# Show what will be changed
printf "\n$TXT01\n # Backup of $FOLDERS (`date +"%H:%M:%S"`):\n$TXT01\n" >>$TMPFILE
echo "--------------[ Change statistics ]--------------" >>$TMPFILE
for FOLDER in $FOLDERS; do
        $RDIFFBIN --compare $FOLDER $BACKUPSERVER::$BACKUPDIR$FOLDER >>$TMPFILE
done
 
# Do the backup
$RDIFFBIN $RDIFFPARAMS $INCLUDEFOLDERS --exclude '**' / $BACKUPSERVER::$BACKUPDIR >>$TMPFILE
 
# Retention
$RDIFFBIN --remove-older-than $RETENTION --force $BACKUPSERVER::$BACKUPDIR >>$TMPFILE
 
# Show statistics
echo "--------------[ Incremental statistics ]--------------" >>$TMPFILE
$RDIFFBIN -l $BACKUPSERVER::$BACKUPDIR >>$TMPFILE
 
printf "\n++++++++++++++++++++++ Backup End at `date +"%H:%M:%S"` +++++++++++++++++++++++" >>$TMPFILE
TIMESTOP=`date +%s`
printf "\n++++++++++++++++++++++ Duration `expr $TIMESTOP - $TIMESTART`sec +++++++++++++++++++++++" >>$TMPFILE
 
f_sendmail
exit 0
