<#	
.SYNOPSIS
util2_killSessions.ps1 kills all Oracle sessions except those owned by Oracle users SYS, SYSTEM and OPCON.
util2_killSessions runs on the same host as the Oracle instance it manages.
	
.DESCRIPTION
util2_killSessions uses pl/sql procedure solife_util2.killSessions

.Parameter oracleSid
ORACLE_SID of Oracle Solife instance. Mandatory.

.Parameter mode
Defines type of run. False for atest run, True for a live run. Possible values are 'TRUE', 'FALSE'. Default is 'FALSE'

.Example 
util2_killSessions -oracleSid orasolifedev -mode 'FALSE'		
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
$sql = @"
set serveroutput on
execute solife_util2.killSessions($mode);
-- Return error from plsql procedure execution
exit SQL.SQLCODE
"@

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
