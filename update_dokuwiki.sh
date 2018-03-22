#!/bin/bash
set -e
 
# Set your install dir
INSTALLDIR=/var/www
 
[[ `whoami` != "root" ]] && { echo "Must be root"; exit 2; }
[[ `pwd` != "$INSTALLDIR" ]] && { echo "You must be in $INSTALLDIR instead in `pwd`"; exit 2; }
 
DOKUFILE=`ls $INSTALLDIR/dokuwiki*.tgz  |awk -F/ '{print $NF}'`
[[ -z $DOKUFILE ]] && { echo "No TAR file found matching dokuwiki*.tgz"; exit 2; }
 
cd $INSTALLDIR
 
echo "Removing old backup dokuwiki.old"
rm -rf dokuwiki.old
 
echo "Backup current Dokuwiki to dokuwiki.old"
mv dokuwiki dokuwiki.old
 
echo "Extracting new TAR"
tar -xzf $DOKUFILE
 
echo "Rename extracted directory to dokuwiki if not yet"
mv `find . -type d -name "dokuwiki-*"` dokuwiki
 
echo "Remove .dist files in the new installation"
find dokuwiki -name *.dist -exec rm -rf {} \;
 
echo "Get local configs and acl.auth.php from previous installation"
find dokuwiki.old/conf -name "*local*" -exec cp -p {} dokuwiki/conf \;
cp -p dokuwiki.old/conf/acl.auth.php dokuwiki/conf
 
echo "Get custom smileys from previous installation"
for i in `awk '{print $NF}' dokuwiki.old/conf/smileys.local.conf`; do
        printf " $i"
        cp dokuwiki.old/lib/images/smileys/$i dokuwiki/lib/images/smileys
done
echo ""
 
echo "Rsync data from previous installation"
rsync -a --delete dokuwiki.old/data dokuwiki
 
echo "Clear update messages"
echo "" > dokuwiki/data/cache/messages.txt
 
echo "Copy active template from previous installation"
TPL=`grep template dokuwiki.old/conf/local.php |cut -f4 -d\'`
cp -pr dokuwiki.old/lib/tpl/$TPL dokuwiki/lib/tpl
 
echo "Copy custom installed plugins"
for i in `ls dokuwiki.old/lib/plugins/`; do
        if [[ ! `ls dokuwiki/lib/plugins/$i 2>/dev/null` ]]; then
                printf " $i"
                cp -pr dokuwiki.old/lib/plugins/$i dokuwiki/lib/plugins
        fi
done
echo ""
 
echo "Fixing permissions"
chown -R www-data dokuwiki/data dokuwiki/lib/plugins
chown www-data dokuwiki/conf dokuwiki/conf/local.php dokuwiki/conf/acl.auth.php
 
/etc/init.d/apache2 reload
