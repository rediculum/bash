#!/bin/bash
#
# Fri Feb  5 10:43:29 CET 2010 / hanr
# Wed Feb 24 10:22:03 CET 2010 / added umask and clear screen
# Mon May 10 21:32:44 CET 2010 / exit if passphrase wrong
#                                vi and gpg binary check
#
 
LASTUMASK=`umask`
ACCOUNTFILE=$HOME/.accounts
VIBIN=`which vi`
GPGBIN=`which gpg`
 
# checks
([ -z $GPGBIN ] || [ -z $VIBIN ]) && { echo "gpg and/or vi not found on this system"; exit 1; }
[ -f $ACCOUNTFILE.swp ] && { echo "File already in use by vi"; exit 1; }
 
# set secure umask
umask 077
 
# decrypt file and exit immediately if passphrase is wrong
$GPGBIN -d $ACCOUNTFILE.gpg > $ACCOUNTFILE || exit 2
 
# edit
$VIBIN $ACCOUNTFILE
 
# encrypt new file and overwrite existing one
echo "Encrypting ..."
$GPGBIN --yes -e -r $USER $ACCOUNTFILE
 
# remove unencrypted file
rm -f $ACCOUNTFILE
 
# restore umask
umask $LASTUMASK
 
# clear the screen
clear
