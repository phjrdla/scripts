<#	
.SYNOPSIS
TransfertsFinanciers.ps1 creates 2 csv files pour 2 given SQL queries

.DESCRIPTION
Detailed and consolidated 


.Parameter oracleSid
oracleSid is used to setup Oracle environment variable ORACLE_SID.

.Parameter schema
schema : clv61xxx schema with which to run the reports

.Parameter reportOut
cvs files created in folder reportOut

.Example  
TransfertsFinanciers -oracleSid orlsol00 -schema clv61prd -reportOut d:\solife-db\csv
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [Parameter(Mandatory=$True) ] [string]$schema,
  [string]$reportDir = 'd:\solife-db\csv'
)

##########################################################################################################
function TransfertsFinanciersEntrees {
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
set feedback off
set pagesize 0
set lines 150
set trimspool on
column "titres" format A140 trunc
column "ligne" format A140 trunc
ttitle '$reportOut'
select 'NOSTRO_LABEL ; NOTRO_NUMBER ; AMOUNT ; DEBIT_CREDIT ; CURRENCY ; EXTERNAL_ACCOUNT ; POLICY_NUMBER' "titres"
from dual
/
select acc.LABEL||' ; '||acc.ACC_NUMBER||' ; '||to_char(m.AMOUNT)||' ; '||m.CRE_DEB||' ; '||nvl(cu.ISO_CODE,' ')||' ; '||ea.IBAN||' ; '||fo.POLICY_NUMBER "ligne"
from CONSOLIDATED_MOVEMENT cm
join movement m on m.CONSOLIDATED_MOVEMENT_OID = cm.oid
join SUB_POSITION sp on sp.oid = m.SUB_POSITION_OID
join position p on p.oid = sp.POSITION_OID
join account acc on acc.oid = p.ACCOUNT_OID
join currency cu on cu.oid = cm.CURRENCY_OID
join BUSINESS_TRANSACTION bt on bt.oid =cm.BUSINESS_TRANSACTION_OID
join EXTERNAL_ACCOUNT ea on ea.oid = cm.EXTERNAL_ACCOUNT_OID
join ACCOUNTING_TRANSACTION atr on atr.oid = m.ACCOUNTING_TRANSACTION_OID
left join ACCOUNTABLE_IMPL ai on ai.oid = atr.ACCOUNTABLE_OID
left join client_order co on co.oid = atr.ACCOUNTABLE_OID
join FINANCIAL_OPERATION fo on (fo.EXTERNAL_ID = ai.GROUP_REF or fo.EXTERNAL_ID = co.GROUP_REF)
where bt.EXTERNAL_ID =
  (select max(bti.external_id) from business_transaction bti
   inner join business_transaction_type btt on bti.transaction_type_oid = btt.oid
   where btt.hard_type = 79 and bti.transaction_state=8)
/
"@

  # Run sqlplus script
 $sql | sqlplus -S $cnx

}
##########################################################################################################

##########################################################################################################
function TransfertsFinanciersConsolides {
  param ( $cnx, $schema, $reportOut )

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
set feedback off
set pagesize 0
set lines 150
set trimspool on
column "titres" format A140 trunc
column "ligne" format A140 trunc
ttitle '$reportOut'
select 'SOURCE_IBAN_ACCOUNT ; TARGET_IBAN_ACCOUNT ; QUANTITY_OR_AMOUNT ; CURRENCY ; EXECUTION_DATE ; SELECTED' "titres"
from dual
/
select payer.IBAN||' ; '||payee.IBAN||' ; '||to_char(eod.QUANTITY_OR_AMOUNT)||' ; '||c.ISO_CODE||' ; '||to_char(co.EXECUTION_DATE)||' ; '||eod.DISPLAY "ligne"
from BUSINESS_TRANSACTION bt
join abstract_business_extension abe on abe.GENERIC_TRANSACTION_OID = bt.oid
join abstract_pc_wrapper apw on apw.CAPITAL_EXTENSION_OID = abe.oid
join GLOBAL_OPERATION go on go.GLOBAL_OP_STARTABLE_OID = apw.oid
join CUSTODIAN_INSTRUCTION ci on ci.GLOBAL_OPERATION_OID = go.oid
join CUSTODIAN_ORDER co on co.oid = ci.ORDER_OID
join ELEMENTARY_OPERATION_DETAIL eod on eod.ELEMENTARY_OPERATION_OID = ci.oid and eod.cid = 2226 -- CustodianInstructionDetail
join CURRENCY c on eod.CURRENCY_OID = c.OID
join EXTERNAL_ACCOUNT payer on payer.oid = eod.PAYER_EXTERNAL_ACCOUNT_OID
join EXTERNAL_ACCOUNT payee on payee.oid = eod.PAYEE_EXTERNAL_ACCOUNT_OID
where bt.EXTERNAL_ID = 
  (select max(bti.external_id) from business_transaction bti
   inner join business_transaction_type btt on bti.transaction_type_oid = btt.oid
   where btt.hard_type = 79 and bti.transaction_state=8)
and eod.AMOUNT_TYPE_CODEID not in (562,563)
/
"@

  # Run sqlplus script
 $sql | sqlplus -S $cnx

}
##########################################################################################################

##########################################################################################################
function getReportName {
  param( $reportDir, $schema, $reportName )
  $reportOut = $reportDir + '\' + $schema + '_' + $reportName + '.csv' 
  return $reportOut
}
##########################################################################################################

$thisScript = $MyInvocation.MyCommand
write-host "ThisScript is $thisScript"

$nls_lang='_BELGIUM'
$env:NLS_LANG=$nls_lang
$env:ORACLE_SID = $oracleSid
#Get-ChildItem Env:ORACLE_SID
write-host "schema is $schema"

# Check directory for reports exists
if ( ! (Test-Path $reportDir) ) {
  write-host "Please create directory $reportDir for reports"
  exit 1
}

#$tstamp = get-date -Format 'yyyyMMddThhmmss'
$tstamp = get-date -Format 'yyyyMMddTHH'
#write-host "time is $tstamp"

# Connect as sys
$cnx = '/ as sysdba'

$reportOut = getReportName $reportDir $schema 'TransfertsFinanciersEntrees' 

write-host "$reportOut"
TransfertsFinanciersEntrees $cnx $schema $reportOut >  $reportOut

$reportOut = getReportName $reportDir $schema 'TransfertsFinanciersConsolides' 
write-host "$reportOut"
TransfertsFinanciersConsolides $cnx $schema $reportOut >  $reportOut

exit 0
