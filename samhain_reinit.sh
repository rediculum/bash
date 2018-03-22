#
# This script reinitializes the Samhain database remotely
# Execute this script immediatly after intentional changes in the system
#
# Thu Feb  3 09:31:56 CET 2011 - hanr
# Sat Jul  2 14:19:09 CET 2011 - added keychain support
#
TARGETHOST=host.domain
SAMNAME=samhain
SSHOPTS="-q"
 
printf "Check SSH keychain: "
if [ -f ~/.keychain/$HOSTNAME-sh ]; then
        . ~/.keychain/$HOSTNAME-sh
        echo "Loaded"
else
        echo "No keychain found. You will be prompted for passphrase"
fi
 
echo "Stopping $SAMNAME process"
ssh $SSHOPTS $TARGETHOST "/etc/init.d/$SAMNAME stop"
 
echo "Reinitialize database"
 
# Delete existing DB and reinitialize a new one
ssh $SSHOPTS $TARGETHOST "rm /var/lib/${SAMNAME}/${SAMNAME}_file; $SAMNAME -t init -p none"
 
# Sign it
ssh $SSHOPTS -t $TARGETHOST "gpg -a --clearsign --not-dash-escaped /var/lib/${SAMNAME}/${SAMNAME}_file"
 
# Exit if signing fails
[[ $? != 0 ]] && exit 2
 
# Rename and set right permissions
ssh $SSHOPTS $TARGETHOST "mv /var/lib/${SAMNAME}/${SAMNAME}_file.asc /var/lib/${SAMNAME}/${SAMNAME}_file;\
                          chmod 640 /var/lib/${SAMNAME}/${SAMNAME}_file"
 
echo "Starting $SAMNAME process"
ssh $SSHOPTS $TARGETHOST "/etc/init.d/$SAMNAME start"
