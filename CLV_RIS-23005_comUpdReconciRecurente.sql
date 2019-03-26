set serveroutput on size 1000000;
set linesize 250
set trimspool on
set pagesize 0
set timing on
set showmode on
set termout on
set lines 200
set trimspool on


declare

PREV_BPI_OID NUMBER(20,0);
RECONCILIATION_D DATE;
NB_FMW_SEL NUMBER (4,0);

-- selection des payments instruction de BT fees et comm dans status paye (reconcilie) et date de derniere modification
Cursor select_pay_inst IS
select pi.oid as PI_OID, pi.payment_instruction_status as PI_STATUS,trunc(nvl(rin.modification_date_time, rin.creation_date_time)) as RECONCI_DATE
from 
    payment_instruction pi
        inner join payment_instruction_split pis on pi.oid = pis.payment_instruction_oid
            inner join payment pa ON pis.payment_oid = pa.oid
                INNER JOIN ABSTRACT_BUSINESS_EXTENSION abe ON abe.oid = pa.CAPITAL_EXTENSION_OID
                    INNER JOIN BUSINESS_TRANSACTION bt ON bt.oid = abe.GENERIC_TRANSACTION_OID AND bt.transaction_state = 18
        inner join reconciliation_instruction rin on pi.oid = rin.PAYMENT_INSTRUC_OUT_OID
where pi.payment_instruction_status in (6) and rin.status = 1
order by pi.oid asc;

-- sélection des commissions payement et des broker paiment instructions qu'il faut corriger parce que commissions non trouvé (com sur fonds non lié à une opération de frais)
Cursor select_BPI_CPA (pPI_OID2 NUMBER) IS
select bpi.oid AS BPI_OID, cpa.oid AS CPA_OID 
from
    payment_instruction pi
        inner join payment_instruction_split pis ON pi.oid = pis.payment_instruction_oid
            INNER JOIN payment pa ON pa.oid = pis.payment_oid
                inner join link_payment_payment_item lppi ON lppi.payment_oid= pa.oid
                    INNER JOIN FC_MOVEMENT_WRAPPER fmw ON fmw.oid = lppi.payment_Item_oid and fmw.is_selected = '1'
                        inner join movement mov on fmw.movement_oid = mov.oid
                            INNER JOIN MOVEMENT_DETAIL MVD ON mov.oid = MVD.MOVEMENT_OID
                                INNER JOIN ELEMENTARY_OPERATION_DETAIL EOD ON MVD.ACCOUNTABLE_DETAIL_OID = EOD.OID
                                    INNER JOIN CLIENT_INSTRUCTION CLI ON EOD.ELEMENTARY_OPERATION_OID = CLI.OID
                                        INNER JOIN GLOBAL_OPERATION GOP ON CLI.GLOBAL_OPERATION_OID = GOP.OID
                                            INNER JOIN FINANCIAL_OPERATION FOP ON GOP.GLOBAL_OP_STARTABLE_OID = FOP.OID
                                                INNER JOIN FEE_AMT_TO_FEE_AMT_ORIGIN FAO ON FOP.OID = FAO.FEE_AMOUNT_ORIGIN_OID
                                                    INNER JOIN FEE_AMOUNT FAM ON FAO.FEE_AMOUNT_OID = FAM.OID
                                                        INNER JOIN FEE_STORE_ACTION FSA ON FAM.OID = FSA.FEE_AMOUNT_OID
                                                            INNER JOIN FSTORE_PAY_ACTION FPA ON FSA.OID = FPA.OID AND EOD.amount_type_codeid = FPA.AMOUNT_TYPE_CODEID AND EOD.sub_amount_type_codeid = FPA.SUB_AMOUNT_TYPE_CODEID
                                                            INNER JOIN FEE_STORE_ACTION_CTXT_PARAMS FSC ON FSA.CONTEXT_PARAMETERS_OID = FSC.OID AND CLI.FIN_INST_OID = FSC.FINANCIAL_INSTRUMENT_OID
                                                                INNER JOIN INVESTMENT_COMMISSION_PAY ICP ON FPA.OID = ICP.FEE_PAYMENT_ACTION_OID
                                                                    INNER JOIN COMMISSION_PAYMENT CPA ON ICP.OID = CPA.OID
                                                                        INNER JOIN BROKER_PAYMENT_INSTRUCTION BPI ON CPA.PAYMENT_INSTRUCTION_OID = BPI.OID
where pi.oid = pPI_OID2 and BPI.reconci_date is null
order by bpi.oid asc, cpa.oid asc;

-- sélection des commissions payement qu'il faut corriger parce que payment désélectionné sur une partie des com d'une opération
Cursor select_CPA (pPI_OID3 NUMBER) IS
select cpa.oid as CPA_OID, mov.oid as MOV_OID
from payment_instruction pi
        inner join payment_instruction_split pis ON pi.oid = pis.payment_instruction_oid
            INNER JOIN payment pa ON pa.oid = pis.payment_oid
                inner join link_payment_payment_item lppi ON lppi.payment_oid= pa.oid
                    INNER JOIN FC_MOVEMENT_WRAPPER fmw ON fmw.oid = lppi.payment_Item_oid and fmw.is_selected = '0'
                        inner join movement mov on fmw.movement_oid = mov.oid
                            INNER JOIN MOVEMENT_DETAIL MVD ON mov.oid = MVD.MOVEMENT_OID
                                INNER JOIN ELEMENTARY_OPERATION_DETAIL EOD ON MVD.ACCOUNTABLE_DETAIL_OID = EOD.OID
                                    INNER JOIN CLIENT_INSTRUCTION CLI ON EOD.ELEMENTARY_OPERATION_OID = CLI.OID
                                        INNER JOIN GLOBAL_OPERATION GOP ON CLI.GLOBAL_OPERATION_OID = GOP.OID
                                            INNER JOIN FINANCIAL_OPERATION FOP ON GOP.GLOBAL_OP_STARTABLE_OID = FOP.OID
                                                INNER JOIN FEE_AMT_TO_FEE_AMT_ORIGIN FAO ON FOP.OID = FAO.FEE_AMOUNT_ORIGIN_OID
                                                    INNER JOIN FEE_AMOUNT FAM ON FAO.FEE_AMOUNT_OID = FAM.OID
                                                        INNER JOIN FEE_STORE_ACTION FSA ON FAM.OID = FSA.FEE_AMOUNT_OID
                                                            INNER JOIN FSTORE_PAY_ACTION FPA ON FSA.OID = FPA.OID AND EOD.amount_type_codeid = FPA.AMOUNT_TYPE_CODEID AND EOD.sub_amount_type_codeid = FPA.SUB_AMOUNT_TYPE_CODEID
                                                            INNER JOIN FEE_STORE_ACTION_CTXT_PARAMS FSC ON FSA.CONTEXT_PARAMETERS_OID = FSC.OID AND CLI.FIN_INST_OID = FSC.FINANCIAL_INSTRUMENT_OID
                                                                INNER JOIN INVESTMENT_COMMISSION_PAY ICP ON FPA.OID = ICP.FEE_PAYMENT_ACTION_OID
                                                                    INNER JOIN COMMISSION_PAYMENT CPA ON ICP.OID = CPA.OID
where pi.oid = pPI_OID3 and cpa.status in (8);   --8 = paid
    
BEGIN
PREV_BPI_OID := 0;

FOR pay_inst In select_pay_inst
LOOP 
    
    dbms_output.put_line('pay_i_oid;' || pay_inst.PI_OID || ';' || pay_inst.PI_STATUS || ';' || pay_inst.RECONCI_DATE); 
    
    RECONCILIATION_D := pay_inst.RECONCI_DATE;

    -- mettre à jour les broker payment instruction et la cpa!        
    FOR bpi_cpa In select_BPI_CPA (pay_inst.PI_OID)
    LOOP 
        dbms_output.put_line('BPI_OID-CPA_OID;;;;' || bpi_cpa.BPI_OID || ';' || bpi_cpa.CPA_OID);
        IF bpi_cpa.BPI_OID <> PREV_BPI_OID THEN
            update BROKER_PAYMENT_INSTRUCTION set reconci_date = RECONCILIATION_D, modification_actor = 'RIS-23005', modification_date_time = systimestamp where oid = bpi_cpa.BPI_OID;
            dbms_output.put_line('Upd_rec;;;;' || bpi_cpa.BPI_OID);
        END IF;
        update COMMISSION_PAYMENT set status = 8, modification_actor = 'RIS-23005', modification_date_time = systimestamp where oid = bpi_cpa.CPA_OID;
        dbms_output.put_line('Upd_cpa_st8;;;;;' || bpi_cpa.CPA_OID);            
        PREV_BPI_OID := bpi_cpa.BPI_OID;
    END LOOP;

    
    -- mettre à jour statut cpa si wrapper est désélectionné mais à condition qu'on ne le paie pas dans une BT suivante    
    FOR cpa_not_selected In select_CPA  (pay_inst.PI_OID)
    LOOP
        dbms_output.put_line('ER2_CPA_OID ;;;;;' || cpa_not_selected.CPA_OID);
        select count(fmw.oid) into NB_FMW_SEL from movement mov
                                            INNER JOIN FC_MOVEMENT_WRAPPER fmw on mov.oid = fmw.movement_oid
                                                INNER JOIN ABSTRACT_BUSINESS_EXTENSION abe ON abe.oid = fmw.CAPITAL_EXTENSION_OID
                                                    INNER JOIN BUSINESS_TRANSACTION bt ON bt.oid = abe.GENERIC_TRANSACTION_OID
                                    where mov.oid = cpa_not_selected.MOV_OID and fmw.is_selected = '1' and bt.transaction_state = 18;
        dbms_output.put_line('N_wrp;;;;;;' ||  NB_FMW_SEL);
        IF NB_FMW_SEL = 0 THEN
            update COMMISSION_PAYMENT set status = 2, modification_actor = 'RIS-23005', modification_date_time = systimestamp where oid = cpa_not_selected.CPA_OID;
            dbms_output.put_line('upd2_CPA;;;;;' || cpa_not_selected.CPA_OID);
        END IF;
    END LOOP;

END LOOP;

COMMIT;
-- ROLLBACK;

END;
/
exit



