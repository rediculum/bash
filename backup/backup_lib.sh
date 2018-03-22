# This is the sourced library for the backup scripts
#
# Fri Dec  3 10:42:04 CET 2010 / hanr
# Sat Jul  2 14:13:58 CET 2011 / added keychain support for ssh-agents
# 
 
### Variables
RDIFFBIN="/usr/bin/rdiff-backup"
RDIFFPARAMS="--print-statistics --create-full-path"
RETENTION="3M"          # keep last 3 months
TMPFILE="/tmp/backup_$HOSTNAME.sh.tmp"                     # Complete path with filename for mail content
EMAIL="hanr"    # Address where content or alert shoult be sent, semicolon sep.
FROM="backup"
DRYRUN=
TXT01="####################################################################################"
 
 
### Functions
function f_keychain()
{
        if [ -f ~/.keychain/$HOSTNAME-sh ]; then
                . ~/.keychain/$HOSTNAME-sh
        else
                f_error "No keychain found on this system"
        fi
}
 
function f_mysqld()
{
        case $1 in
                start)
                        /etc/init.d/mysql $1 >>$TMPFILE
                        pidno=`ps ax |grep mysqld_safe |grep -v grep`
                        if [ -z "$pidno" ]; then
                                printf "\n!!!!!!! MYSQL SERVER NOT RUNNING OR FAILED TO START !!!!!!!" >>$TMPFILE
                        else
                                echo $pidno >>$TMPFILE
                        fi
                        ;;
                stop)
                        /etc/init.d/mysql $1 >>$TMPFILE
                        ;;
        esac
}
 
function f_sendmail()
{
        if [ $DRYRUN ]; then
                cat $TMPFILE
        else
                cat $TMPFILE |mailx -a from:$FROM -s "$HOSTNAME Backup" $EMAIL
        fi
}
 
function f_error()
{
        printf "!!! Skipped !! $1 (`date +"%H:%M:%S"`)\n$TXT01\n" >$TMPFILE
        f_sendmail
        exit 1
}
