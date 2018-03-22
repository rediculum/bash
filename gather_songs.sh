#!/bin/bash
#
# Collect MP3 from an album on mybook and get a zip file
#
# Die Feb 24 15:12:35 CET 2009 hanr
# Do 2. Jul 08:45:58 CEST 2009 placed $ALBUM in doublequotes to search more than 1 word in album name
#
### Variables
 
MYORIGIN=`pwd`
MYBOOK=/mybook/Music
ALBUM=$1
 
# Script
function usage {
        echo "Usage: $0 \"album name\" tar|zip"
        exit 1
}
if [ "$ALBUM" = "" ]; then
        usage
fi
cd $MYBOOK
case "$2" in
        tar)
                find */*"$ALBUM"* -name "*.mp3" |sed 's/ /\\ /g' |xargs tar -cvzf "$ALBUM".tar.gz
                mv "$ALBUM".tar.gz $MYORIGIN
                ;;
        zip)
                find */*"$ALBUM"* -name "*.mp3" -exec zip "$ALBUM".zip {} \;|sed 's/ /\\ /g'
                mv "$ALBUM".zip $MYORIGIN
                ;;
        *)
                usage
                ;;
esac
cd $MYORIGIN
exit 0
### EOF
