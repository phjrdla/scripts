#!/bin/ksh

DATE=$(date '+%Y-%m-%d_%H:%M:%S')
RMAN_LOG="/u04/rman/backup_full_${DATE}.lst"

[[ $ORACLE_HOME = "" ]] && { print "ORACLE_HOME is not defined"; exit; }

typeset -u srvname
if (( $# == 1 ))
then
  srvname=$1
else
  while [[ -z "$srvname" ]]
  do
    read srvname?"Enter primary database unique name (q to quit) :"
    [[ $srvname = 'Q' ]] && exit
  done
fi

# get password for account sys for srvname
usrname=SYS
usrpwd=$(/home/oracle/scripts/getpwd.sh $srvname $usrname)
[[ $usrpwd = "" ]] && { print "No credential found for $usrname and $srvname"; exit; }
cnx="${usrname}/${usrpwd}"

database_role=$(sqlplus -S "$cnx@$srvname as sysdba" <<!
set pagesize 0
set heading off
set feedback off
select database_role
from v\$database
/
!
)

print "Database $srvname is a $database_role"
[[ $database_role != 'PRIMARY' ]] && { print "$srvname name is not a primary, exit"; exit; }

# to tail RMAN logfile
[[ -f $RMAN_LOG ]] && rm -f $RMAN_LOG
touch  $RMAN_LOG
tail -f  $RMAN_LOG &

rman target $cnx@$srvname @$DG_SCRIPTS/DGbackup_full.rman LOG $RMAN_LOG

