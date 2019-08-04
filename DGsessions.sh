#!/bin/ksh

cat <<!
Returns sessions on database
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
set lines 250
set pages 200

column module     format a30 trunc
column username   format a10 trunc
column program    format a25 trunc
column module     format a20 trunc
column osuser     format a15 trunc
column machine    format a15 trunc
column terminal   format a15 trunc
column schemaname format a15 trunc
column "kill_cmd" format a50 trunc

select sid
      ,serial#
      ,username
      ,command
      ,state
      ,status
      ,program
      ,module
      ,schemaname
      ,osuser
      ,machine
      ,terminal
      ,'alter system kill session '''||to_char(sid)||','||to_char(serial#)||''';' "kill_cmd"
  from v\$session
 where schemaname != 'SYS'
 order by module
/
!

