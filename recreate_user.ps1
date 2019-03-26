<#	
.SYNOPSIS
recreate_user script is used to drop and create SOLIFE schema in orlsol03_prd (first step to refresh non-prod env)

.DESCRIPTION
Used to drop and create SOLIFE schema in orlsol03_prd
Applies to orlsol03_prd only 
should run locally. No remote connection to database 

.Parameter oracleSid
oracleSid is used to setup Oracle environment variable ORACLE_SID. Mandatory

.Parameter schema 
schema owning abstract_principal table. Mandatory.
Possible values are CLV61INT

.Example
recreate_user -OracleSid ORLSOL03 -Schema clv61int
		
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [ValidatePattern('^ORL+[a-zA-B0-9]+')][string]$oracleSid,
  [Parameter(Mandatory=$True) ] [ValidatePattern('^CLV61+[a-zA-B0-9]+')] [string]$schema
)

$thisScript = $MyInvocation.MyCommand
write-host "ThisScript is $thisScript"

$env:ORACLE_SID = $oracleSid
Get-ChildItem Env:ORACLE_SID
write-host "schema is $schema"

# Build sql statements
$cmd = 'drop user ' + $schema + ' cascade;'
$cmd1 = 'CREATE USER ' + $schema + ' IDENTIFIED BY CLV_61_INT DEFAULT TABLESPACE "BSBIS_DATA_CLV61" TEMPORARY TABLESPACE "TEMP" QUOTA UNLIMITED ON "BSBIS_DATA_CLV61" QUOTA UNLIMITED ON "BSBIS_INDEX_CLV61" ACCOUNT UNLOCK;'	
$cmd2 = 'GRANT CONNECT TO ' + $schema + ';'
$cmd3 = 'GRANT DBA TO ' + $schema + ';'
$cmd4 = 'GRANT SOLIFE_USER TO ' + $schema + ';'
$cmd5 = 'GRANT EXECUTE on SYS.DBMS_LOB TO ' + $schema + ';'

# Connect as sys
$cnx = "/ as sysdba"
$dual = 'select * from dual;'

  $sql = @"
set echo on
$cmd
$cmd1
$cmd2
$cmd3
$cmd4
$cmd5
"@

# Run sqlplus script
$sql | sqlplus -S $cnx

exit 
