#!/bin/ksh
#
# Switches standby db to primary and reciproquely
# 
#[[ $# != 3 ]] && { print "Usage is : $0 db_name1 db_name2"; exit; }

#cat <<!
#Script switchover.sh switches standby and primary roles for specified databases 
#usage is : switchover.sh dbname1 dbnmae2
#Databases names can be specified in any order
#!



# Suffixe for DG broker (dgmgrl) services
brosfx='DGMGRL'

# cleanup
sotrc='switchover.trc'
[[ -f $sotrc ]] && rm $sotrc

# 1st database
typeset -u dbname1
while [[ -z "$dbname1" ]]
do
  read dbname1?"First database unique name :"
done
print "First database is $dbname1"
brosrv1=${dbname1}_$brosfx

# 2nd database
typeset -u dbname2
while [[ -z "$dbname2" ]]
do
  read dbname2?"Second database unique name :"
done
print "Second database is $dbname2"
brosrv2=${dbname2}_$brosfx

#
print "Testing services for DG broker"
for brosrv in $brosrv1 $brosrv2
do
  echo $brosrv
  tnsping $brosrv 5 | tee -a $sotrc
  rc=$?
  if (( rc == 0 ))
  then
    print "Listener for $brosrv is ok"
  else
    print "Listener fails for $brosrv, exit"
    exit
  fi
done

# checks connectivy to databases
cat <<!
==================================================
Checks connectity to databases using $brosrv1 $brosrv2
!

# get password for account sys for srvname
usrname=SYS
srvname=$dbname1
usrpwd=$(/home/oracle/scripts/getpwd.sh $srvname $usrname)
[[ $usrpwd = "" ]] && { print "No credential found for $usrname and $srvname"; exit; }
cnx="${usrname}/${usrpwd}"

for brosrv in $brosrv1 $brosrv2
do
  cat <<! | sqlplus -S "$cnx@$brosrv as sysdba" | tee -a $sotrc
set linesize 250
SELECT DATABASE_ROLE, DB_UNIQUE_NAME INSTANCE, OPEN_MODE, PROTECTION_MODE, PROTECTION_LEVEL, SWITCHOVER_STATUS 
FROM V\$DATABASE
/
!
  rc=$?
  if (( rc == 0 ))
  then
    print "Connectity to database using $brosrv is ok"
  else
    print "Connectity to database using $brosrv fails, exit"
    exit
  fi
done
!


cat <<!
==================================================
Identifies current primary and secondary databases
!
PRIM='PRIMARY'
STBY='PHYSICAL STANDBY'

dbrole=$(sqlplus -S "$cnx@$brosrv1 as sysdba" <<! | tee -a $sotrc
set pages 0
set feedback off
set heading off
SELECT DATABASE_ROLE
FROM V\$DATABASE
/
!
)

# Find out to what points brosrv1
print "dbrole for $brosrv1 is $dbrole"
if [[ $dbrole = $PRIM ]]
then
  brosrvp=$brosrv1
  brosrvs=$brosrv2
  dbnamep=$dbname1
  dbnames=$dbname2
else
  brosrvp=$brosrv2
  brosrvs=$brosrv1
  dbnamep=$dbname2
  dbnames=$dbname1
fi

print "Primary database pointed by $brosrvp"
print "Standby database pointed by $brosrvs"


cat <<!
==================================================
Display broker status
!
dgmgrl <<! | tee -a $sotrc
connect $cnx@$brosrvp
show configuration
!

cat <<!
Is the Broket configuration status "success" ?
and
Do primary and standby databases in Broker configuration
match database roles identified ?
!

typeset -u answer
answer=''
while [[ -z "$answer" ]]
do
  read answer?"Is Broker configuration correct (Y/N'?" 
done 

[[ $answer != 'Y' ]] && { print "Exit $0"; exit; }

cat <<!
==================================================
Switchover of $dbnamep and $dbnames
!
answer=''
while [[ -z "$answer" ]]
do
  read answer?"Proceed with switchover (Y/N'?" 
done 

[[ $answer != 'Y' ]] && { print "No databases switchover "; exit; }

cat <<!
==================================================
Databases details before switchover
!
dgmgrl <<! | tee -a $sotrc
connect $cnx@$brosrvp
show configuration verbose;
show database verbose $dbnamep
show database verbose $dbnames
!

# Performs 3 logfile switches before switch over
sqlplus -S "$cnx@$brosrvp as sysdba" <<!
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
exit
!

dgmgrl <<! | tee -a $sotrc
connect $cnx@$brosrvp
switchover to $dbnames
!

#dgmgrl <<! | tee -a $sotrc
#connect $cnx@$brosrvs
#show configuration verbose;
#show database verbose $dbnamep
#show database verbose $dbnames
#!

