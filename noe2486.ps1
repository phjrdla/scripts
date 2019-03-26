<#	
.SYNOPSIS
noe2486.ps1 invokes function sys.noe2486

.DESCRIPTION
Dans le cadre du chargement ODS, il faudrait créer un script qui execute la requite SQL en pièce jointe au ticket maître.
Ensuite il faudrait faire la somme dela colonne ERROR_COUNT.
Si cette somme est supérieure ouéègale à une certaine valeur X faire sortir le script avec un code 90.
Cette valeur X sera passer en parameter du script par OPCON


.Parameters oracleSid
oracleSid is used to setup Oracle environment variable ORACLE_SID.
schema : clv61xxx schema
error_count_max : above error_count_max code 90 is returned 

.Example select noe2486 ( 10 ) from dual;	
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [Parameter(Mandatory=$True) ] [string]$schema,
  [Parameter(Mandatory=$True) ] [int]$error_count_max 
)

$thisScript = $MyInvocation.MyCommand
#write-host "ThisScript is $thisScript"

$env:ORACLE_SID = $oracleSid
Get-ChildItem Env:ORACLE_SID
write-host "schema is $schema"
write-host "error_count_max is $error_count_max"

$tstamp = get-date -Format 'yyyyMMdd-hhmmss'
write-host "time is $tstamp"

# Connect as sys
$cnx = "/ as sysdba"

# build sqlplus script
$sql = @"
set serveroutput off
set heading off
set feedback off
set newpage 0
alter session set current_schema=$schema;
select noe2486 ( $error_count_max ) from dual;
-- Return error from plsql function execution
exit SQL.SQLCODE
"@

# Run sqlplus script
[string]$code = $sql | sqlplus -S $cnx
write-host "code returned is $code"

exit $code