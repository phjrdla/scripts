[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$connectStr,
  [Parameter(Mandatory=$True) ] [string]$username,  [Parameter(Mandatory=$True) ] [string]$password = $( Read-Host -asSecureString "Input password" )
)

$cnx = "$username/$password@$connectStr"

# Server on which script is running
$computerName = (Get-WmiObject -Class Win32_ComputerSystem -Property Name).Name

write-output '##########################################################################################################'
$tstamp = get-date -Format 'yyyyMMdd-hhmmss'
write-output "Daily checks for $connectStr on $tstamp"
write-output '##########################################################################################################'

##########################################################################################################
function ShowDgmgrlConf {
  param ( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output `n"This is function $thisFunction"
  write-output "`Show data guard broker configuration"


  # Run dgmgrl show configuration command
  dgmgrl $cnx 'show configuration verbose;'
  
}

ShowDgmgrlConf $cnx 'show configuration verbose;'

##########################################################################################################
function ShowDataguardStatus {
  param ( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output `n"This is function $thisFunction"
  write-output "`Show Dataguard status"

  # Corruped blocks
  $sql = @"
set serveroutput off
set heading on
set pagesize 200
set lines 200
column message format a100 wrap
column TSTAMP format A17
select facility, severity, message_num, error_code, callout
      ,to_char(timestamp, 'DD/MM/YY HH24:MI:SS') TSTAMP
      ,message
  from v`$dataguard_status
 order by message_num desc
 fetch first 50 rows only
/
"@

  # Run sqlplus script
  $sql | sqlplus -S $cnx
  
}

ShowDataguardStatus $cnx

##########################################################################################################
function ShowDataguardConfig {
  param ( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output `n"This is function $thisFunction"
  write-output "`Show Dataguard config"

  # Corruped blocks
  $sql = @"
set serveroutput off
set heading on
set pagesize 10
set lines 120
col CURRENT_SCN	format 999999999999999
select *
  from v`$dataguard_config
/
"@

  # Run sqlplus script
  $sql | sqlplus -S $cnx
  
}

ShowDataguardConfig $cnx

##########################################################################################################
function CheckOracleServices {
   # Oracle Listeners
  write-output "`nOracle listeners running"
  Get-Service *TNS* | where { $_.Status -eq 'Running' } | format-table Status, Name, DisplayName

  write-output "`nOracle listeners stopped"
  Get-Service *TNS* | where { $_.Status -eq 'Stopped' } | format-table Status, Name, DisplayName

   # Database Services
  write-output "Oracle services running"
  Get-Service OracleService* | where { $_.Status -eq 'Running' } | format-table Status, Name, DisplayName

  write-output "`nOracle services stopped"
  Get-Service OracleService* | where { $_.Status -eq 'Stopped' } | format-table Status, Name, DisplayName
}

CheckOracleServices

##########################################################################################################
function CheckDbHealth {
  param ( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nDatabase integrity checks"
  
  $tstamp = get-date -Format 'yyyyMMdd-hhmmss'

  # DBMS_HM run_names
  $dic_integrity_run = "DIC_$tstamp"
  $db_integrity_run = "DB_$tstamp"
  $redo_integrity_run = "REDO_$tstamp"

  $sql = @"
set long 20000
set numwidth 10
set lines 250
set pages 1000
prompt Dictionary Integrity Check
begin
  dbms_hm.run_check(check_name => 'Dictionary Integrity Check', run_name => '$dic_integrity_run');
end;
/
prompt 'DB Structure Integrity Check'
select dbms_hm.get_run_report('$dic_integrity_run') from dual;
begin
  dbms_hm.run_check(check_name => 'DB Structure Integrity Check', run_name => '$db_integrity_run');
end;
/
prompt Redo Integrity Check
select dbms_hm.get_run_report('$db_integrity_run') from dual;
begin
  dbms_hm.run_check(check_name => 'Redo Integrity Check', run_name => '$redo_integrity_run');
end;
/
select dbms_hm.get_run_report('$redo_integrity_run') from dual;
exit
"@

 $sql | sqlplus -S $cnx
}

CheckDbHealth $cnx

##########################################################################################################
function CheckCorruptedBlocks {
  param ( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output `n"This is function $thisFunction"
  write-output "`Checking corrupted blocks"

  # Corruped blocks
  $sql = @"
set serveroutput off
set heading off
set pagesize 0
select count(1)
  from v`$database_block_corruption
/
"@

  # Run sqlplus script
  [string]$cnt = $sql | sqlplus -S $cnx
  if ( ($cnt -as [int] ) -ne $null ) {
    $cnt = [int]$cnt
  } else {
    write-output 'cnt can''t be cast to int'
    break
  }

  if ( $cnt -eq 0 ) {
    write-output "No corrupted block found"
  } else {
      write-output "$cnt blocks found corrupted"
      write-output 'check v`$database_block_corruption' 
  }

}

CheckCorruptedBlocks $cnx

##########################################################################################################
function GetHost_Name {
  param ( $cnx )
  
  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  #write-output "`nThis is function $thisFunction"

  $sql = @"
set serveroutput off
set heading off
set pagesize 0
select upper(trim(host_name))
  from v`$instance              
/
"@

  [string]$host_name = $sql | sqlplus -S $cnx
  $host_name
}

$host_name = GetHost_Name $cnx

##########################################################################################################
function CheckLastBackup {
  param ( $cnx )
  
  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nChecking when last backup was done"

  $sql = @"
set serveroutput off
set heading off
set pagesize 0
select (trunc(sysdate) - trunc(start_time)) - 1
  from v`$rman_backup_job_details
 where start_time = ( select max(start_time)  
                        from v`$rman_backup_job_details)
/
"@

  [string]$days = $sql | sqlplus -S $cnx
  if ( ($days -as [int] ) -ne $null ) {
    $days = [int]$days
  } else {
      write-output 'days can''t be cast to int'
      return
  }

  if ( $days -ge 0 ) {
    write-output "Last backup was done $days days ago"
  }
}

CheckLastBackup $cnx

##########################################################################################################
function Last20Backup {
  param( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nListing last 20 backups"

  $sql = @"
set linesize 80
set pages 25
col "StartedAt" format a17 trunc
col "EndedAt" format a17 trunc
col "OutDevType" format a10 trunc
col status format a10 trunc
col input-type format a10 trunc
select to_char(start_time,'DD/MM/YY HH24:MI:SS') "StartedAt"
      ,to_char(end_time,'DD/MM/YY HH24:MI:SS') "EndedAt"
      ,output_device_type "OutDevType"
      ,status
      ,input_type
 from v`$rman_backup_job_details
order by start_time desc
fetch first 20 rows only
/
"@
  $sql | sqlplus -S $cnx
}

Last20Backup $cnx
 
##########################################################################################################
function ListRmanBackup {
  param( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nListing Rman backups younger than a week"

  $sql = @"
connect target $cnx
list backup summary completed after 'sysdate - 8';
"@
  $sql | rman
}

ListRmanBackup $cnx

##########################################################################################################
function CheckResourceUse {
  param( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nChecking some DBMS resources usage"

  $sql = @"
ttitle 'Resources usage and limit'
set linesize 80
col resource_name format a20 trunc
col "LimitValue" format 99,999
select resource_name
      ,current_utilization
      ,max_utilization
      ,to_number(limit_value) "LimitValue"
 from v`$resource_limit
where trim(limit_value) not in ('0','UNLIMITED')
  and ( (to_number(limit_value) - max_utilization)/to_number(limit_value) ) >= 0
/
"@
  $sql | sqlplus -S $cnx
}

CheckResourceUse $cnx 

##########################################################################################################
function ListHitRatio {
  param( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nLast 10 buffer hit ratios"

  $sql = @"
ttitle 'Buffer cache hit ratio'
set lines 80
col "TimeStamp" format A17 trunc
col "HitRario" format 99.999
set pages 25
SELECT to_char(BEGIN_INTERVAL_TIME,'YY/MM/DD HH24:MI:SS') "TimeStamp"
     , ROUND( (( 1 - ( SUM(DECODE(STAT_NAME,'physical reads',VALUE,0))/ 
                            ( SUM(DECODE(STAT_NAME,'db block gets',VALUE,0)) + SUM(DECODE(STAT_NAME,'consistent gets',VALUE,0)) )
                          ))*100),4 ) "HitRatio" 
  FROM DBA_HIST_SYSSTAT SS
     , DBA_HIST_SNAPSHOT S
 WHERE SS.SNAP_ID=S.SNAP_ID   
 GROUP BY BEGIN_INTERVAL_TIME
 ORDER BY BEGIN_INTERVAL_TIME desc
 fetch first 10 rows only
 /
"@
  $sql | sqlplus -S $cnx
}

ListHitRatio $cnx 

##########################################################################################################
function CheckFreeSpace {
  param( $cnx )
  
  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nChecking % of free space in tablespaces"

  $sql = @"
ttitle 'Current % of free space per tablespace'
set lines 80
set pages 50
col PCT_FREE format 999,99
col PCT_USED format 999,99
col TOT_MB   format 999,999
col FREE_MB  format 999,999
col tablespace_name format a40 trunc
select round( (dfs.bytes/ddf.bytes)*100, 2) PCT_FREE
      ,round( (1 - dfs.bytes/ddf.bytes)*100, 2) PCT_USED
      ,ddf.tablespace_name
      ,round(ddf.bytes/(1024*1024),0) TOT_MB
      ,round(dfs.bytes/(1024*1024),0) FREE_MB
  from (select TABLESPACE_NAMe, sum(bytes) bytes, count(1) nof from dba_data_files group by TABLESPACE_NAME) ddf
      ,(select tablespace_name, sum(bytes) bytes from dba_free_space group by tablespace_name) dfs
 where ddf.tablespace_name = dfs.tablespace_name
 order by ddf.tablespace_name
/
"@
  $sql | sqlplus -S $cnx
}

CheckFreeSpace $cnx 

##########################################################################################################
function CheckUsedSpace {
  param( $cnx )
  
  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nChecking tablespaces usage"

  $sql = @"
ttitle '% used space wrt tablespace maximum size'
set lines 80
set pages 50
col PCT_USED format 999,99
col tablespace_name format a40 trunc
select round(used_percent,2) PCT_USED
      ,tablespace_name
  from dba_tablespace_usage_metrics
 order by used_percent desc
 /
"@
  $sql | sqlplus -S $cnx
}

CheckUsedSpace $cnx 

##########################################################################################################
function CheckSharedPoolReserved {
  param( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nChecking shared pooled requests failures"

  $sql = @"
ttitle 'Shared_Pool_Reserved statistics : watch request_failures'
set linesize 200
set pagesize 50
set trimspool on
select request_failures "req_fail"
     , last_failure_size "fail_size" 
     , free_space "free_space"
     , avg_free_size "avg_free_size"
     , free_count "free_count"
     , max_free_size "max_free_size"
     , used_space "used_space"
     , avg_used_size "avg_used_size"
     , used_count "used_count"
     , max_used_size "max_used_size"
     , requests "requests"
     , request_misses "request_misses"
     , last_miss_size "last_miss_size" 
     , max_miss_size "max_miss_size" 
FROM v`$shared_pool_reserved
/
"@
  $sql | sqlplus -S $cnx
}

CheckSharedPoolReserved $cnx

##########################################################################################################
function CheckBlockers {
  param( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nChecking if any session blocked"

  $sql = @"
ttitle 'Session blockers'
select *
  from dba_blockers
/
"@
  $sql | sqlplus -S $cnx
}

CheckBlockers $cnx

##########################################################################################################
function CheckAlertLog {
  param( [Parameter(Mandatory=$True) ] $cnx,
         [int]$nol = 1000 )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nChecking errors in alert log"

# Alert log location
  $sql = @"
set pagesize 0
set lines 100
set feedback off
set trimspool on
select value
  from v`$diag_info
 where name = 'Diag Trace'
/
"@
  [string]$tracePath = $sql | sqlplus -S $cnx

# Instance name
  $sql = @"
set pagesize 0
set lines 100
set feedback off
set trimspool on
select instance_name
  from v`$instance
/
"@
  [string]$instance_name = $sql | sqlplus -S $cnx

# Build alert log name
  $alertLog = "$tracePath\alert_$instance_name.log"
  If ( -not (Test-Path $alertLog) ) { 
    write-error "Could not find $alertLog, exit"
   return
  } else {
    write-output "Inspecting $alertLog"
  }

  # number of errors found
  $cnt = ( Get-Content -Path $alertLog -Tail $nol | Select-String -Pattern 'ORA-' ).length
  if ( $cnt -eq 0 ) {
    write-output "No error found in last $nol lines of alert log"
  }
  else {
    # list Oracle errors and following 3 lines
    Get-Content -Path $alertLog -Tail $nol | Select-String -Pattern 'ORA-' -Context 0,3 
  }
  
}

#$computerName.GetType().fullname
#$computerName.Length
#$host_name.GetType().FullName
#$host_name.Length
#write-output "$computerName $host_name"
if ( $host_name -match $computerName ) {
  CheckAlertLog $cnx
} 
else {
  Write-Output "Alert log is on remote server $host_name"
}

##########################################################################################################
function CheckORAGeneric {
  param( [Parameter(Mandatory=$True) ] $cnx,
         [int]$nol = 1000  )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  write-output "`nThis is function $thisFunction"
  write-output "`nLooking ORA-600 ORA-700 and ORA-7445 generic errors"
  
  # Error codes checked
  $patterns = 'ORA-[0]{0,2}600', 'ORA-[0]{0,2}700', 'ORA-[0]{0,1}7445'

  # Locate trace directory
  $sql = @"
set pagesize 0
set lines 100
set feedback off
set trimspool on
select value
  from v`$diag_info
 where name = 'Diag Trace'
/
"@
  [string]$tracePath = $sql | sqlplus -S $cnx

# Instance name
  $sql = @"
set pagesize 0
set lines 100
set feedback off
set trimspool on
select instance_name
  from v`$instance
/
"@
  [string]$instance_name = $sql | sqlplus -S $cnx

  $alertLog = "$tracePath\alert_$instance_name.log"
  If ( -not (Test-Path $alertLog) ) { 
    write-error "Could not find $alertLog, exit"
   return
  } else {
    write-output "Inspecting $alertLog"
  }

  foreach ( $pattern in $patterns) {
    # number of errors found
    write-output "Looking for $pattern"
    $cnt = ( Get-Content -Path $alertLog -Tail $nol | Select-String -Pattern $pattern ).length
    if ( $cnt -eq 0 ) {
      write-output "No occurency found in last $nol lines of alert log"
    }
    else {
      # list Oracle errors and following 3 lines
      Get-Content -Path $alertLog -Tail $nol | Select-String -Pattern $pattern -Context 3,3 
    }
  }
  
}

if ( $host_name -match $computerName ) {
  CheckORAGeneric $cnx
} 
else {
  Write-Output "Alert log is on remote server $host_name"
}

write-output '##########################################################################################################'
$tstamp = get-date -Format 'yyyyMMdd-hhmmss'
write-output "End of daily checks for $connectStr on $tstamp"
write-output '##########################################################################################################'
