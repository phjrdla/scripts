<#	
.SYNOPSIS
ExecSqlStmt executes a SQL command using sqlplus utility. 
SQL string is provided in a file.

.DESCRIPTION
ExecSqlStmt uses Oracle SQL*Plus to execute a SQL string on an Oracle instance and schema 
passed as parameters.
The SQL string is terminated with a ';' and can be provided as a parameter or in a file.

.Parameter oracleSid
oracleSid is used to setup Oracle environment variable ORACLE_SID. Mandatory

.Parameter schema 
schema owning abstract_principal table. Mandatory.

.Parameter stmtFile
stmtFile is a file containing ';' terminated SQL statements to be executed by sqlplus

.Parameter stmtOut
stmtOut is a file receiving the output of StmtFile

.Parameter mode
mode is used to choose the type of run, 'FALSE' for a simulation, 'TRUE' for live. Default is FALSE.

.Example
execSqlStmt -OracleSid ORLSOL05 -Schema clv61re7 -Passwd Mo2pace -stmtFile c:\temp\UpdateEmp.sql -stmtOut c:\temp\UpdateEmp.out -mode false
		
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [Parameter(Mandatory=$True) ] [string]$schema,
  [Parameter(Mandatory=$True) ] [string]$passwd,
  [Parameter(Mandatory=$True) ] [ValidateLength(3,80)] [string]$stmtFile,
  [Parameter(Mandatory=$True) ] [ValidateLength(3,80)] [string]$stmtOut,
  [ValidateSet('TRUE','FALSE')] [string]$mode = 'false' 
)

$thisScript = $MyInvocation.MyCommand
write-host "ThisScript is $thisScript"

$env:ORACLE_SID = $oracleSid
Get-ChildItem Env:ORACLE_SID
write-host "schema is $schema"
write-host "stmtfile is $stmtFile"
write-host "stmtOut is $stmtOut"
write-host "mode is $mode"

# Check that stmtFile is there ...
If ( Test-Path $stmtfile ) {
  $stmt = get-content -Path $stmtFile -Raw
} 
else {
  write-host "Could not find $stmtFile!`nexit."
  exit
}

# Delete a previous stmtOut
If ( Test-Path $stmtOut ) {
  Remove-Item -Force -literalPath $stmtOut
  write-host ("previous $stmtOut removed")
} 

# Wrap statement to catch output
if ( $mode.ToUpper() -eq 'TRUE' ) {
  $sql = @"
set timing on
set trimspool on
spool $stmtOut
$stmt
spool off
"@
}
else {
  $sql = @"
select 'this is a test' from dual;
"@
}

# Connection to database
$cnx = "$schema/$passwd"

# Run sqlplus script
$sql | sqlplus -S $cnx

# Check that stmtOut is there ...
If ( -NOT (Test-Path $stmtOut) ) {
  write-host "Could not find $stmtOut!`nexit."
  exit
}

exit 
