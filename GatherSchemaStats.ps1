<#	
.SYNOPSIS
GatherSchemaStats.ps1 computes schema statistics

.DESCRIPTION
GenRapportsBatch.ps1 computes schema statistics

.Parameter connectStr
SQL*NET string to connect to instance. Mandatory.

.Parameter schema
Schema for which statistics are computed. Mandatory.

.Example  GatherSchemaStats -connectStr orlsol00 -schema clv61prd
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$connectStr,
  [Parameter(Mandatory=$True) ] [string]$schema
)

##########################################################################################################
function SchemaStats {
  param ( $cnx, $schema )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  #write-output `n"This is function $thisFunction"
  #write-output "`List description for all batches"

  # 
  $sql = @"
set termout off
set echo off
set feedback off
alter session set current_schema=$schema
/
execute dbms_stats.gather_schema_stats( user , degree=>DBMS_STATS.DEFAULT_DEGREE, cascade=>DBMS_STATS.AUTO_CASCADE, options=>'GATHER AUTO', no_invalidate=>False )
/
"@

  # Run sqlplus script
 $sql | sqlplus -S -MARKUP "HTML ON" $cnx

}
##########################################################################################################

$thisScript = $MyInvocation.MyCommand
write-host "ThisScript is $thisScript"

# Connect as sys
$cnx  = 'bip/Koek1081@orlsol00_prm'

$tstamp = get-date -Format 'yyyyMMddThhmmss'
#write-host "time is $tstamp"

write-host "Gather Schema Stats"
SchemaStats $cnx $schema 
