<#	
.SYNOPSIS
ODS_Set_Deleted.ps1 handles duplicates in SOLIFE & ODS schemas

.DESCRIPTION
DFS-9898 & RIT-37125
Corriger l’anomalie de chargement ODS en flaggant comme « DELETED » les objets de l’ODS qui ont été supprimés dans Solife. 

.Parameter oracleSid
oracleSid : SID database containing Solife & ODS schemas

.Parameter action
action : ROLLBACK or COMMIT changes, default is ROLLBACK

.Example 
ods_set_delete.psa ORLSOL00 ROLLBACK

.Example
ods_set_delete.psa ORLSOL00

.Example
ods_set_delete.ps1 ORLSOL00 COMMIT
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$True) ] [string]$oracleSid,
  [ValidateSet('COMMIT','ROLLBACK','commit','rollback')] [string]$action = 'ROLLBACK'
)

$env:ORACLE_SID = $oracleSid

# Connect as sys
$cnx = "/ as sysdba"

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

UPDATE solife_it0_ods.roletoroletarget
   SET roletoroletarget.ods`$is_deleted = 'Y', roletoroletarget.ods`$current_version = 'N'
 WHERE roletoroletarget.technicalidentifier IN (SELECT itkdwh_audit.obj_cid || ':' || itkdwh_audit.obj_oid FROM clv61prd.itkdwh_audit);
$action;
UPDATE solife_it0_ods.roletothirdparty
   SET roletothirdparty.ods`$is_deleted = 'Y', roletothirdparty.ods`$current_version = 'N'
 WHERE roletothirdparty.technicalidentifier IN (SELECT itkdwh_audit.obj_cid || ':' || itkdwh_audit.obj_oid FROM clv61prd.itkdwh_audit);
$action;
UPDATE solife_it0_ods.address
   SET address.ods`$is_deleted = 'Y', address.ods`$current_version = 'N'
 WHERE address.technicalidentifier IN (SELECT itkdwh_audit.obj_cid || ':' || itkdwh_audit.obj_oid FROM clv61prd.itkdwh_audit);
$action;
exit
"@

# Run sqlplus script
$sql | sqlplus -S $cnx

Exit 0