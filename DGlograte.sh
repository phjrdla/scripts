#!/bin/ksh

cat <<!
Computes number of logs per day and per hour
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
set pages 100
set lines 160
set feedback off
column "DG Date" format a10 trunc
column "12AM" format a5  
column "01AM" format a5  
column "02AM" format a5  
column "03AM" format a5  
column "04AM" format a5  
column "05AM" format a5  
column "06AM" format a5  
column "07AM" format a5  
column "08AM" format a5  
column "09AM" format a5  
column "10AM" format a5  
column "11AM" format a5  
column "12PM" format a5  
column "01PM" format a5  
column "02PM" format a5  
column "03PM" format a5  
column "04PM" format a5  
column "05PM" format a5  
column "06PM" format a5  
column "07PM" format a5  
column "08PM" format a5  
column "09PM" format a5  
column "10PM" format a5  
column "11PM" format a5  
SELECT TO_CHAR(TRUNC(FIRST_TIME),'Mon DD') "DG Date",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'00',1,0)),'9999')      "12AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'01',1,0)),'9999')      "01AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'02',1,0)),'9999')      "02AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'03',1,0)),'9999')      "03AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'04',1,0)),'9999')      "04AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'05',1,0)),'9999')      "05AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'06',1,0)),'9999')      "06AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'07',1,0)),'9999')      "07AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'08',1,0)),'9999')      "08AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'09',1,0)),'9999')      "09AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'10',1,0)),'9999')      "10AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'11',1,0)),'9999')      "11AM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'12',1,0)),'9999')      "12PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'13',1,0)),'9999')      "01PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'14',1,0)),'9999')      "02PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'15',1,0)),'9999')      "03PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'16',1,0)),'9999')      "04PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'17',1,0)),'9999')      "05PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'18',1,0)),'9999')      "06PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'19',1,0)),'9999')      "07PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'20',1,0)),'9999')      "08PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'21',1,0)),'9999')      "09PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'22',1,0)),'9999')      "10PM",
TO_CHAR(SUM(DECODE(TO_CHAR(FIRST_TIME,'HH24'),'23',1,0)),'9999')      "11PM"
FROM V\$LOG_HISTORY
GROUP BY TRUNC(FIRST_TIME)
ORDER BY TRUNC(FIRST_TIME) DESC
/
!

