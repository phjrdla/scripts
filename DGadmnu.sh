#!/bin/ksh

# Scripts location
SCRIPTS_HOME='/home/oracle/scripts'

. $SCRIPTS_HOME/DGenvselect.sh

# Environment variable ORACLE_HOME must be defined to use this script
[[ $ORACLE_HOME = "" ]] && { print 'Environment is not defined, use . oraenv'; exit; }

# CGDIS main menu
typeset -r SLEEPTIME=15

REVON=$(tput smso)  # Reverse on.
REVOFF=$(tput rmso) # Reverse off.

while :
do
    clear
    print "\t    $REVON CGDIS Data Guard Systems scripts $REVOFF"
    print "\t    Current environment is $ORACLE_SID $REVOFF"
    print
    print
    print "\tOptions:"
    print "\t---------------------------------------------"
    print "\t 1) DG System summary             11) Local listener status"
    print "\t 2) DG System health              12) Local listener start"
    print "\t 3) DG Configuration Details      13) Local database shutdown"
    print "\t 4) DG Database Health            14) Local database startup"
    print "\t 5) DG DB role                    15) DG switchover"
    print "\t 6) DG Archive gap                16) DG active services"
    print "\t 7) DG Last sequence applied      17) DG sessions"
    print "\t 8) DG Logs rate                  18) Local databases running"
    print "\t 9)                               19) DG RMAN backups summary"
    print "\t10) DG Statistics (standby only)  20) DG Primary full RMAN backup"
    print
    print "\n\tOther Options:"
    print "\t----------------"
    print "\tr) Refresh screen"
    print "\tq) Quit"
    print
    print "\tEnter your selection: r\b\c"
    read selection
    if [[ -z "$selection" ]]
        then selection=r
    fi

    case $selection in
        1)  print "\nData Guard System summary"
            $SCRIPTS_HOME/DGsummary.sh $ORACLE_SID
            sleep 10
            ;;
        2)  print "\nData Guard System health"
            $SCRIPTS_HOME/DGconfiguration.sh $ORACLE_SID
            sleep 10
            ;;
        3)  print "\nData Guard Configuration Details"
            $SCRIPTS_HOME/DGconfigurationdetails.sh $ORACLE_SID
            sleep $SLEEPTIME
            ;;
        4)  print "\nData Guard Database Health"
            $SCRIPTS_HOME/DGDBhealth.sh
            sleep 30
            ;;
        5)  print "\nData Guard Database Role"
            $SCRIPTS_HOME/DGDBrole.sh
            sleep $SLEEPTIME
            ;;
        6)  print "\nData Guard Archive Gap"
            $SCRIPTS_HOME/DGgap.sh $ORACLE_SID
            sleep $SLEEPTIME
            ;;
        7)  print "\nData Guard Last Sequence Applied"
            $SCRIPTS_HOME/DGlogsequence.sh $ORACLE_SID
            sleep $SLEEPTIME
            ;;
        8)  print "\nData Guard Logs per hour"
            $SCRIPTS_HOME/DGlograte.sh $ORACLE_SID
            sleep 15
            ;;
        9)  print "\nOption 9"
            sleep $SLEEPTIME
            ;;
        10)  print "\nDG basic statistics on standby "
            $SCRIPTS_HOME/DGstats.sh
            sleep $SLEEPTIME
            ;;
        11)  print "\nLocal listener status"
            $SCRIPTS_HOME/DGlistenerstatus.sh
            sleep 15
            ;;
        12)  print "\nLocal listener start"
            $SCRIPTS_HOME/DGlistenerstart.sh
            sleep $SLEEPTIME
            ;;
        13)  print "\nLocal database shutdown"
            $SCRIPTS_HOME/DGshutdown_database.sh $ORACLE_SID
            sleep $SLEEPTIME
            ;;
        14)  print "\nLocal database startup"
            $SCRIPTS_HOME/DGstartup_database.sh $ORACLE_SID
            sleep $SLEEPTIME
            ;;
        15)  print "\nDG switchover"
            $SCRIPTS_HOME/DGswitchover.sh
            sleep $SLEEPTIME
            ;;
        16)  print "\nDG active services"
            $SCRIPTS_HOME/DGactiveservices.sh
            sleep 15
            ;;
        17)  print "\nDG sessions"
            $SCRIPTS_HOME/DGsessions.sh
            sleep $SLEEPTIME
            ;;
        18)  print "\nLocal databases running"
             ps -ef | grep pmon | grep -v grep
            sleep 5
            ;;
        19)  print "\nRMAN backups summary"
            $SCRIPTS_HOME/DGbackupsummary.sh $ORACLE_SID
            sleep 15
            ;;
        20)  print "\nPrimary full RMAN backup"
            $SCRIPTS_HOME/DGbackup_full.sh $ORACLE_SID
            sleep $SLEEPTIME
            ;;
      r|R)  continue
            ;;
      q|Q)  print
            exit
            ;;
        *)  print "\n$REVON Invalid selection $REVOFF"
            sleep 1
            ;;
    esac
done

