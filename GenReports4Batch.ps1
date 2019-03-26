<#	
.SYNOPSIS
GenReports4Batch.ps1 generates html ouput for reports on batch jobs

.DESCRIPTION
GenRapportsBatch.ps1 generates html ouput for reports on batch jobs

.Parameter oracleSid
oracleSid is used to setup Oracle environment variable ORACLE_SID.

.Parameter schema
schema : clv61xxx schema with which to run the reports

.Example 
  GenReports4Batch -oracleSid orlsol08 -schema clv61in1	-reportOut d:\solife-db\html
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [Parameter(Mandatory=$True) ] [string]$schema,
  [Parameter(Mandatory=$True) ] [string]$dateParam,
  [string]$reportDir = 'd:\solife-db\html'
)

##########################################################################################################
function ListBatches {
  param ( $cnx, $schema, $reportOut )

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
set feedback on
set pagesize 50
ttitle '$reportOut'
SELECT *
FROM (
select bj.job_id,
description,
case bj.batch_job_status_codeid
when 0 then 'PENDING'
when 2 then 'PREPRO'
when 3 then 'PROCESSING'
when 4 then 'POSTPRO'
when 5 then 'SEL_ERR'
when 6 then 'PREPRO_ERR'
when 7 then 'PRO_ERR'
when 8 then 'POSTPRO_ER'
when 9 then 'CANCELLED'
when 10 then 'COMPLETED'
when 11 then 'PAUSED'
when 12 then 'PAUSING'
when 13 then 'CANCELLING'
when 14 then 'ERROR'
when 15 then 'COMPLE_ERR'
else
'NA' end as status,
(bj.modification_date_time - bj.creation_date_time) as duration,
bj.creation_date_time,
--bj.modification_date_time,
bji.execution_count,
bji.error_count
from batch b
inner join batch_job bj on bj.BATCH_OID = b.oid
inner join batch_job_info bji on bj.info_oid = bji.oid
where description in( 'Processing of auto actions','Indexation Batch','Rescheduling batch','Coverage Charges Batch'
                     ,'Guaranteed rate reinvestment batch','Billing Reminder Batch','Financial operation batch','Generic fees'
                     ,'Financial Transfers Execution Batch','Benefit payment Batch','Payment instructions out batch','Regular Service Batch'
                     ,'Policy Notification Batch','Market order batch','Accounting transaction batch','Life certficate for annuities'
                     ,'claim review batch','Cooling Off Switch Batch','Term batch')
order by bj.job_id desc
)
WHERE rownum <= 21
/
"@

  # Run sqlplus script
 $sql | sqlplus -S -MARKUP "HTML ON" $cnx

}
##########################################################################################################

##########################################################################################################
function Valuation {
  param ( $cnx, $schema, $reportOut, $dateParamSQL )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
  #write-output `n"This is function $thisFunction"
  #write-output "`List description for all batches"

  # Corruped blocks
  $sql = @"
set termout off
set echo off
set feedback off
alter session set current_schema=$schema
/
set feedback on
set pagesize 50
ttitle '$reportOut'
SELECT *
FROM (
select bj.job_id,
SUBSTR(bji.PARAMETER, INSTR(bji.PARAMETER,'<object')+23,
INSTR(bji.PARAMETER,'</object>')-INSTR(bji.PARAMETER,'<object')-23) as policyValuation,
bj.creation_date_time,
bj.modification_date_time,
(bj.modification_date_time - bj.creation_date_time) as duration,
bji.execution_count, bji.error_count
from batch b
inner join batch_job bj on bj.BATCH_OID = b.oid
inner join batch_job_info bji on bj.info_oid = bji.oid
inner join batch_job_input bji on bji.BATCH_JOB_OID = bj.oid
where description = 'Valuation batch'
and bj.creation_date_time > to_date ('$dateParamSQL','DD/MM/YY')
order by bj.job_id desc
)
WHERE rownum <= 5
/
"@

  # Run sqlplus script
 $sql | sqlplus -S -MARKUP "HTML ON" $cnx

}
##########################################################################################################

##########################################################################################################
function getReportName {
  param( $reportDir, $schema, $reportName, $timeStamp)
  $reportOut = $reportDir + '\' + $schema + '_' + $reportName + '_'  + $tstamp + '.html' 
  return $reportOut
}
##########################################################################################################

$thisScript = $MyInvocation.MyCommand
write-host "ThisScript is $thisScript"

$env:ORACLE_SID = $oracleSid
#Get-ChildItem Env:ORACLE_SID
write-host "schema is $schema"

# Check directory for reports exists
if ( ! (Test-Path $reportDir) ) {
  write-host "Please create directory $reportDir for reports"
  exit 1
}

$tstamp = get-date -Format 'yyyyMMddThhmmss'
#write-host "time is $tstamp"

# Connect as sys
$cnx = '/ as sysdba'

$reportOut = getReportName $reportDir $schema 'ListBatches' $tstamp 
write-host "$reportOut"
ListBatches $cnx $schema $reportOut >  $reportOut

$reportOut = getReportName $reportDir $schema 'Valuation' $tstamp 
write-host "$reportOut"
Valuation $cnx $schema $reportOut $dateParam >  $reportOut

exit 0
