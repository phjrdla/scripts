<#	
.SYNOPSIS
reset_principal_passwd script updates in table abstract_principal column password for a specified name

.DESCRIPTION
Used to reset OPCON's and ESOL's password in table abstract_principal
Applies to non production environments only
should run locally. No remote connection to database 

.Parameter oracleSid
oracleSid is used to setup Oracle environment variable ORACLE_SID. Mandatory. Fixed to orlsol03

.Parameter schema 
schema owning abstract_principal table. Mandatory. Fixed to CLV61INT

.Parameter name
name is the account to update. Mandatory.
Possible values are OPCON and ESOL

.Parameter mode
mode is used to choose the type of run, 'FALSE' for a simulation, 'TRUE' for live. Default is FALSE.

.Example
reset_principal_passwd -oracleSid ORLSOL06 -schema clv61usr -name opcon -mode false

.Example
reset_principal_passwd -oracleSid ORLSOL06 -schema clv61usr  -name esol -mode false
		
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [Parameter(Mandatory=$True) ] [string]$schema,
  [Parameter(Mandatory=$True) ] [ValidateSet('OPCON','ESOL')] [string]$name,
  [ValidateSet('TRUE','FALSE')] [string]$mode = 'false' 
)

$thisScript = $MyInvocation.MyCommand
write-host "ThisScript is $thisScript"

$env:ORACLE_SID = $oracleSid
Get-ChildItem Env:ORACLE_SID

write-host "schema is $schema"
write-host "name is $name"
write-host "mode is $mode"

$passwd = @{}
$passwd['OPCON'] = '2w291tk3b61v201y202wq1h2z3122' 
$passwd['ESOL']  = '382k2pn2d261h2q1392b2t2l3c2115'

# Build sql statement
$cmd = 'update ' + $schema + '.abstract_principal set password = ' + "'" + $passwd[$name.ToUpper()] +  "' where name = " + "'" + $name.ToUpper() + "';"

# Connect as sys
$cnx = "/ as sysdba"
$dual = 'select * from dual;'

if ( $mode.ToUpper() -eq 'TRUE' ) {
  $sql = @"
set echo on
$cmd
"@
}
else {
$sql = @"
set echo on
prompt $cmd
"@
}

# Run sqlplus script
$sql | sqlplus -S $cnx

exit 
