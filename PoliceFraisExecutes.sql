REM police dont les frais ont ete executes

set lines 150
set pages 10000
set COLSEP ';'

ttitle 'POLICE DONT LES FRAIS ONT ETE EXECUTES'

column PR_CODE format a30 trunc
column IDENTIFIER format a30 trunc

select distinct pol.policy_number, ap2.string_value AS PR_CODE,fd.IDENTIFIER ,sc_fee.next_date
from scheduled_fee sc_fee
inner join fee fee on fee.oid = sc_fee.fee_oid
inner join policy pol on pol.oid = fee.fee_owner_oid
inner join fee_target_to_fee_def target on target.oid = fee.fee_target_to_fee_def_oid
inner join FEE_DEFINITION fd on fd.oid = target.FEE_DEFINITION_OID
inner join PRODUCT_COMPONENT_IMPL PCI on POL.oid = PCI.POLICY_IMPL_OID
inner join COMMERCIALIZED_PRODUCT_WRAPPER CPW on PCI.oid = CPW.PRODUCT_COMPONENT_OID
inner join ABSTRACT_PRODUCT PRO on CPW.ABSTRACT_PRODUCT_OID = PRO.OID
inner join aom_entity ae1 on pro.aom_entity_oid = ae1.oid
inner join aom_property ap1 on ae1.oid = ap1.parent_entity_oid
inner join aom_entity ae2 on ap1.persistence_capable_value_oid = ae2.oid
inner join aom_property ap2 on ae2.oid = ap2.parent_entity_oid
inner join aom_property_type apt on ap2.property_type_oid = apt.oid AND apt.name='Product Code'
where pol.POLICY_STATUS_CODEID = 0
and sc_fee.NEXT_DATE > to_date('01/10/2018', 'dd/mm/yyyy')
and fd.identifier <> 'BELGIAN_TAX_ADVANCE'
order by fd.identifier, pol.policy_number;
