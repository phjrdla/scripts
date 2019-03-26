<#	
.SYNOPSIS
Solife_Update_AfterReschedBatch.ps1 - RIS-21023/RIT-37145

.DESCRIPTION
Quittance à ne pas générer dans Solife. 

.Parameter oracleSid
oracleSid : SID database containing Solife & ODS schemas

.Parameter action
action : ROLLBACK or COMMIT changes, default is ROLLBACK

.Example 
solife_Update_AfterReschedBatch.ps1 ORLSOL00 COMMIT

#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [ValidateSet('COMMIT','ROLLBACK','commit','rollback')] [string]$action = 'ROLLBACK'
)

$env:ORACLE_SID = $oracleSid

# Connect as sys
$cnx = "clv61prd/CLV_61_PRD"

# build sqlplus script
$sql = @"
set exitcommit off
set timing on
set termout on
set lines 200
set pages 0
set echo on
set showmode on

WHENEVER SQLERROR EXIT SQL.SQLCODE;

update BILL set status=5 /*status annul CANCELLED */,modification_date_time=sysdate, modification_actor='RIS-21023'
where oid in (SELECT
    bill.oid        
  FROM bill_component
       JOIN bill ON (bill.oid = bill_component.bill_oid)
       JOIN generic_coverage ON (generic_coverage.oid = bill_component.component_target_oid)
       JOIN coverage_slice ON (coverage_slice.generic_coverage_oid = generic_coverage.oid)
 WHERE bill_component.cid = 6002 /*prime*/
       AND bill_component.premium_component_type = 0 /*prime*/
       AND generic_coverage.main_coverage=1 /*limiter a 1 bill component*/
       AND coverage_slice.TYPE = 1 /*slice prime */
       AND bill.TYPE = 5 /*uniquement periodic premium */ 
       AND bill.start_date = coverage_slice.validity_date /*date effet bill = date validité slice migré qui est une date future correspondant a la fin de la préassurance */
       AND bill.status=1 /*bill planifiée uniquement*/
       AND coverage_slice.migrated=1 /*slice migré uniquement*/
       AND coverage_slice.status=0 /*slice active uniquement*/); 

 CALL CLV_LOG_QUERY('RIS-21023');
$action;
exit
"@

# Run sqlplus script
$sql | sqlplus -S $cnx

Exit 0