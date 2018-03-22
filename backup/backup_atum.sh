#!/bin/bash
#
# BACKUP SCRIPT
#
# Usage: backup_server.sh [-n]
#
# Fri Jul  7 16:55:21 CEST 2006 / Added MySQL Stop-Start-Check
# Mon Oct 15 18:20:48 CEST 2007 / Added exit code if HD couldn't be mounted
# Tue Dec 11 23:02:18 CET 2007 / Added /usr/local/sbin to backup and -p para to cp command
# Tue May  6 10:02:57 CEST 2008 / Added new procedure: mount backup-disk before backup and umount after
# Wed May 21 09:59:15 CEST 2008 / Personalized for Server
# Tue Jul  8 10:54:20 CEST 2008 / Changed cp command to rsync. Added for loop for folders to be backed
#                                 Added combo backup for nas and server with uname check
#                                 Not umount anymore
# Mon Nov 24 13:22:06 CET 2008 / Added mybook mirroring
# Thu Feb  5 22:20:49 CET 2009 / Modifed for only 1 server
# Tue Feb 24 14:13:59 CET 2009 / Removed mybook mirroring. Is now on mybook_sync.sh
# Fri Sep  4 16:46:37 CET 2009 / Added /var/lib/ldap to FOLDERS
# Wed Feb 24 09:51:17 CET 2010 / Optimized complete code with funcs and printf
# Wed Aug 18 14:01:22 CET 2010 / Changed rsync to rdiff-backup for incremental backup
# Fri Dec  3 10:16:07 CET 2010 / Added retention for increments
#                                Include library for common variables and functions
# Fri Aug 19 18:20:56 CET 2011 / Added package list file into /root
 
 
### Config
FOLDERS="/var/log /var/www /var/httpd /var/lib/mysql /var/lib/ldap /var/lib/postgresql /home /etc /root"     # Separate with spaces
BACKUPDISK="/mybook"                            
BACKUPDIR="$BACKUPDISK/backup/server"
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
 
# Check if Backup Disk is mounted
if [ `mount |grep "$BACKUPDISK " >/dev/null` ]; then
        f_error "$BACKUPDISK not mounted"
fi
 
printf "++++++++++++++++++++++ Backup Start at `date +"%H:%M:%S"` +++++++++++++++++++++++\n" >$TMPFILE
 
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
 
 
f_mysqld stop
 
#  Building include list
for FOLDER in $FOLDERS; do
        INCLUDEFOLDERS="$INCLUDEFOLDERS --include $FOLDER "
done
 
# Show what will be changed
printf "\n$TXT01\n # $FOLDERS backuped (`date +"%H:%M:%S"`):\n$TXT01\n" >>$TMPFILE
echo "--------------[ Change statistics ]--------------" >>$TMPFILE
for FOLDER in $FOLDERS; do
        $RDIFFBIN --compare $FOLDER $BACKUPDIR$FOLDER >>$TMPFILE
done
 
# Do the backup
$RDIFFBIN $RDIFFPARAMS $INCLUDEFOLDERS --exclude '**' / $BACKUPDIR >>$TMPFILE
 
# Retention
$RDIFFBIN --remove-older-than $RETENTION --force $BACKUPDIR >>$TMPFILE
 
echo "--------------[ Incremental statistics ]--------------" >>$TMPFILE
$RDIFFBIN -l $BACKUPDIR >>$TMPFILE
 
f_mysqld start
 
printf "\n++++++++++++++++++++++ Backup End at `date +"%H:%M:%S"` +++++++++++++++++++++++" >>$TMPFILE
TIMESTOP=`date +%s`
printf "\n++++++++++++++++++++++ Duration `expr $TIMESTOP - $TIMESTART`sec +++++++++++++++++++++++" >>$TMPFILE
 
f_sendmail
exit 0
