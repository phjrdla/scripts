<#	
.SYNOPSIS
tlog.ps1 displays alert log for a given ORACLE_SID
.DESCRIPTION
tlog uses Oracle utility Datapump to perform aschema dump and to zip it. 

.Parameter oracleSid
oracleSid is mandatatory

.Parameter n
Number of alert log last lines to display 

.Parameter wait
watch alert log and display last n lines conitnuoulsy

.Example tlog.ps1 -oracleSid orasolifedev -n 10  -wait y	
#>

[CmdletBinding()] param(
 [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [int]$n = 100,
  [string]$wait = 'N'
)

$env:ORACLE_SID = $oracleSid


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
  [string]$tracePath = $sql | sqlplus -S '/ as sysdba'

Write-Output "oracleSid is $oracleSid"

$alertLog = "$tracePath\alert_$oracleSid.log"

write-output $alertLog

If ( -not (Test-Path $alertLog) ) { 
  write-error "Could not find $alertLog, exit"
  return
}


Write-Output $wait 

if ( $wait -eq 'Y' ) {
  Get-Content -Path $alertLog -Tail $n -Wait
} else {
  Get-Content -Path $alertLog -Tail $n
}