#!/bin/ksh

# Starts up a local database.

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

# get password for account sys for databae
#usrpwd=$(/home/oracle/scripts/getpwd.sh $srvname SYS)
#cnxsys="SYS/${usrpwd}@${srvname}_DGMGRL as sysdba"
#cnxsys="SYS/${usrpwd}@${srvname} as sysdba"

ORAENV_ASK=NO
ORACLE_SID=$srvname
. oraenv
ORAENV_ASK=YES

sqlplus -S '/ as sysdba'  <<!
set echo on
startup
!

