#!/bin/ksh

cat <<!
Shows Data Guard system health
Check sections <Members:> and <Configuration Status:>
Primary and Standby databases should be active
Configuration status should be Success
!

typeset -u srvname
if (( $# == 1 ))
then
  srvname=$1
else
  while [[ -z "$srvname" ]]
  do
    read srvname?"Enter database unique name (q to quit) :"
    [[ $srvname = 'Q' ]] && exit
  done
fi

# get password for account SYS for service name
usrname=SYS
usrpwd=$(/home/oracle/scripts/getpwd.sh $srvname $usrname)
[[ $usrpwd = "" ]] && { print "No credential found for $usrname and $srvname"; exit; }
cnxsys="${usrname}/${usrpwd}@$srvname"

dgmgrl <<!
connect $cnxsys
show configuration
!
