<#	
.SYNOPSIS
lockUsers script invokes pl/sql procedure solife_util2.abstract_principal with action parameter 'LOCK'
	
.DESCRIPTION
Called with 'LOCK' parameter abstract_principal locks Oracle accounts found in abstract_principal with column locked=0. SYS, SYSTEM, DBSNMP and OPCON accounts are excluded.


.Parameters oracleSid
oracleSid is used to setup Oracle environment variable ORACLE_SID. 
schema owning abstract_principal table
mode is used to choose the type of run, 'FALSE' for a simulation, 'TRUE' for a live run


.Example util2.lockUsers -oracleSid orasolifedev -schema clv61dev -mode 'FALSE'		
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [Parameter(Mandatory=$True) ] [string]$schema,
  [ValidateSet('TRUE','FALSE')] [string]$mode = 'false' 
)

$thisScript = $MyInvocation.MyCommand
write-host "ThisScript is $thisScript"

$env:ORACLE_SID = $oracleSid
Get-ChildItem Env:ORACLE_SID
write-host "schema is $schema"
write-host "mode is $mode"

$tstamp = get-date -Format 'yyyyMMdd-hhmmss'
write-host "time is $tstamp"

# Connect as sys
$cnx = "/ as sysdba"

# build sqlplus script
$sql = @"
set serveroutput on
execute solife_util2.unlockUsers('$schema', $mode);
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
