#!/bin/ksh

cat <<!
finds the archive gap between primary and standby
Should be 0
!

typeset -u srvname
if (( $# == 1 ))
then
  srvname=$1
else
  while [[ -z "$srvname" ]]
  do
    read srvname?"Enter database unique name(q to quit) :"
    [[ $srvname = 'Q' ]] && exit
  done
fi

# get password for account sys for srvname
usrname=SYS
usrpwd=$(/home/oracle/scripts/getpwd.sh $srvname $usrname)
[[ $usrpwd = "" ]] && { print "No credential found for $usrname and $srvname"; exit; }
cnxsys="${usrname}/${usrpwd}@$srvname as sysdba"

sqlplus -S $cnxsys  <<!
set lines 200
prompt FIND THE ARCHIVE LAG BETWEEN PRIMARY AND STANDBY:

select LOG_ARCHIVED-LOG_APPLIED-1 "LOG_GAP" 
  from (SELECT MAX(SEQUENCE#) LOG_ARCHIVED
          FROM V\$ARCHIVED_LOG 
         WHERE DEST_ID=1 
           AND ARCHIVED='YES'),
       (SELECT MAX(SEQUENCE#) LOG_APPLIED
          FROM V\$ARCHIVED_LOG 
         WHERE DEST_ID=2 
           AND APPLIED='YES')
/
!

