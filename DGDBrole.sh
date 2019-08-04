#!/bin/ksh

cat <<!
Returns database role (primary/standby)
!

typeset -u srvname
while [[ -z "$srvname" ]]
do
  read srvname?"Enter database unique name (q to quit) :"
  [[ $srvname = 'Q' ]] && exit
done

# get password for account sys for srvname
usrname=SYSTEM
usrpwd=$(/home/oracle/scripts/getpwd.sh $srvname $usrname)
[[ $usrpwd = "" ]] && { print "No credential found for $usrname and $srvname"; exit; }
cnx="${usrname}/${usrpwd}@$srvname"

sqlplus -S $cnx <<!
set lines 200
SELECT name, db_unique_name, open_mode, database_role
FROM V\$DATABASE
/
column host_name format a30 trunc
column "Startup at" format a17 
select instance_name
      ,host_name
      ,to_char(startup_time,'DD/MM/YY HH24:MI:SS') "Startup at"
      ,status
from v\$instance
/
!

