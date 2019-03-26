<#	
.SYNOPSIS
pkg_solife_util2 creates pl/sql package pkg_solife_util2 on specified database
	
.DESCRIPTION
pkg_solife_util2 has 2 procedures, enable_restricted and disable_restriced, to enable/disable restricted mode on specified database
after killing user sessions 

.Parameters oracleSid
oracleSid is used to setup Oracle environment variable ORACLE_SID. 
mode is used to choose the type of run, 'FALSE' for a simulation, 'TRUE' for a live run

.Example pkg_solife_util2 -oracleSid orasolifedev -mode 'FALSE'		
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [Parameter(Mandatory=$True) ] [ValidateSet('TRUE','FALSE')] [string]$mode = 'false' 
)

$thisScript = $MyInvocation.MyCommand
write-host "ThisScript is $thisScript"

$env:ORACLE_SID = $oracleSid
Get-ChildItem Env:ORACLE_SID
write-host "mode is $mode"

$tstamp = get-date -Format 'yyyyMMdd-hhmmss'
write-host "time is $tstamp"

# Connect as sys
$cnx = "/ as sysdba"

# build sqlplus script
if ( $mode -eq 'TRUE' ) {
$sql = @"
set serveroutput on
-- create or replace package
@pkg_solife_util2
-- Return error from plsql procedure execution
exit SQL.SQLCODE
"@
}
else {
$sql = @"
set serveroutput on
select * from dual;
-- Return error from execution
exit SQL.SQLCODE
"@
}

# Run sqlplus script
$sql | sqlplus -S $cnx

# Catch pl/sql return code propagated to LASTEXITCODE
$SQLRC = $LASTEXITCODE
write-host "SQLRC is $SQLRC"

$EcofCode = $SQLRC
if ( $EcofCode -eq 0 ) {
  $Ecoftxt = "Success"
}
else {
  $Ecoftxt = "Suspect"
}

# Return pl/sql return code to host
exit $EcofCode
