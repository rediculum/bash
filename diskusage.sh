#!/bin/bash
#
# Script zum Anzeigen der Groesse von gehosteten Verzeichnissen.
# Ein html Dokument wird ebenso erstellt
#
# Son Mai  5 15:06:30 GMT 2002 / rha
# Tue Dec 11 21:57:35 CET 2007 / Script mit for-Schleife optimiert und Table
# Do 2. Jul 08:55:52 CEST 2009 / Optimized
#
# Variables
host="/var/httpd"
output=/var/httpd/www.runlevel.ch/www/hosts.php
 
# Script
echo "<table>" > $output
for i in `ls -d $host/*`; do
        echo "<tr align=right><td> `echo $i | cut -f4 -d'/'`" >> $output
        echo ":</td>" >> $output
        result=`du -shP $i | cut -f 1` # Human readable
        resultdet=`du -sP $i | cut -f 1` # in KB
        echo "<td>$result ($resultdet KB)</td></tr>" >> $output
done
echo "</table>" >> $output
echo "<br><br><font size=1>(crontab wrote diskusage.sh at "`date '+%e. %B %Y'`\) >> $output
