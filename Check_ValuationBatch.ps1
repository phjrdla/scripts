<#	
.SYNOPSIS
Check_ValuationBatch.ps1 invokes function sys.Check_ValuationBatch

.DESCRIPTION
Dans le cadre du chargement ODS, il faudrait créer un script qui execute la requite SQL en pièce jointe au ticket maître.
Ensuite il faudrait faire la somme dela colonne ERROR_COUNT.
Si cette somme est supérieure ouéègale à une certaine valeur X faire sortir le script avec un code 90.
Cette valeur X sera passer en parameter du script par OPCON

.Parameter oracleSid
oracleSid is used to setup Oracle environment variable ORACLE_SID.

.Parameter schema
schema : clv61xxx schema

.Parameter error_count_max
error_count_max : above error_count_max script returns a 90 exit code 

.Parameter creation_date_time
Mandatory. Format 'DD/MM/YY'

.Example Check_ValuationBatch.ps1 -oracleSid orlsol08 -schema clv61in1 -error_count_max 100	-creation_date_time '10/01/19'
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [Parameter(Mandatory=$True) ] [string]$schema,
  [Parameter(Mandatory=$True) ] [int]$error_count_max,
  [Parameter(Mandatory=$True) ] [string]$creation_date_time
)

$env:ORACLE_SID = $oracleSid

#Get-ChildItem Env:ORACLE_SID
#write-host "schema is $schema"
#write-host "error_count_max is $error_count_max"

# Connect as sys
$cnx = "/ as sysdba"

# build sqlplus script
$sql = @"
set serveroutput off
set heading off
set feedback off
set newpage 0
alter session set current_schema=$schema;
select Check_ValuationBatch ($error_count_max, '$creation_date_time') from dual;
exit
"@

# Run sqlplus script
#[string]$code = $sql | sqlplus -S $cnx
#$code
[Int]$error_count_Sum = $sql | sqlplus -S $cnx
write-host "error_count_sum is $error_count_sum"

$error_count_Sum = 4;
IF ( $error_count_Sum -ge $error_count_max ) { 
	Exit 90
}
# Else { 
#	Exit 0
#}
