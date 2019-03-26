<#	
.SYNOPSIS
ExecSqlStmtCnx executes a SQL command using sqlplus utility. 
SQL string is provided in a file. Output filename is built from input file.

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
stmtOut defines where output of StmtFile should go. Default is NO

.Parameter mode
mode is used to choose the type of run, 'FALSE' for a simulation, 'TRUE' for live. Default is FALSE.
		
.Example
ExecSqlStmt2Out.ps1 -oracleSid orlsol00 -schema clv61prd -pass xxxxxx -stmtFile d:\solife-db\scripts\CheckMouvementsFinanciers.sql -mode TRUE

.Example
ExecSqlStmtDev.ps1 -oracleSid orlsol00 -schema clv61prd -pass xxxxxx -stmtFile d:\solife-db\scripts\IdentificationMouvementsFinanciers.sql -stmtOut c:\temp\IdentificationMouvementsFinanciers.out-mode TRUE

#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [Parameter(Mandatory=$True) ] [string]$schema,
  [Parameter(Mandatory=$True) ] [string]$passwd,
  [Parameter(Mandatory=$True) ] [ValidateLength(3,80)] [string]$stmtFile,
  [ValidateLength(3,80)] [string]$stmtOut = 'NO',
  [ValidateSet('TRUE','FALSE')] [string]$mode = 'false' 
)

$thisScript = $MyInvocation.MyCommand
write-host "ThisScript is $thisScript"

$env:ORACLE_SID = $oracleSid
#Get-ChildItem Env:ORACLE_SID
#write-host "schema is $schema"
#write-host "stmtfile is $stmtFile"
#write-host "mode is $mode"

# Check that stmtFile is there ...
If ( Test-Path $stmtFile ) {
  $stmt = get-content -Path $stmtFile -Raw
} 
else {
  write-host "Could not find $stmtFile!`nexit."
  exit
}

# Build sql statement to execute
if ( $mode.ToUpper() -eq 'TRUE' ) {
  # Statement output not caught    
  $sql = $stmt
}
else {
  $sql = @"
select 'this is a test' from dual;
"@
}

# Connection to database
$cnx = "$schema/$passwd"

# Setup return code 
[int]$val = 0

# For single numeric value 
if ( $stmtOut -eq 'NO' ) {
  # Run sqlplus script, output returned in val variable
  $val = $sql | sqlplus -SILENT $cnx
}

# When outfile required
else {
  $sql | sqlplus -SILENT $cnx > $stmtOut

  # Check that stmtOut is there ...
  If ( -NOT (Test-Path $stmtOut) ) {
    $val = 1
    write-host "Could not find $stmtOut!`nexit."
  }

}

exit $val
