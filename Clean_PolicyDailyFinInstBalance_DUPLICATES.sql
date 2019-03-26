SET ECHO OFF
SET TIME ON
SET SERVEROUTPUT ON
SET PAGESIZE 1000
SET FEEDBACK OFF

COLUMN TS NEW_VALUE var_ts

SELECT TO_CHAR (SYSDATE, 'yyyy-mm-dd_hh24miss') AS ts FROM DUAL;

SPOOL Clean_PolicyDailyFinInstBalance_Duplicates_&&VAR_TS..log

ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy-mm-dd hh24:mi:ss';

SELECT SYSDATE FROM DUAL;

SET TIMING ON

PROMPT
PROMPT =============================================================
PROMPT Drop the TMP_CLEAN_POLDAILYFININSTBAL table if it exists
PROMPT =============================================================

BEGIN
  FOR rec IN (SELECT table_name
                FROM user_tables
               WHERE table_name LIKE 'TMP_CLEAN_POLDAILYFININSTBAL%') LOOP
    DBMS_OUTPUT.put_line ('Dropping ' || rec.table_name || ' table');

    EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' PURGE';
  END LOOP;
END;
/

PROMPT
PROMPT ======================================================================================================
PROMPT Create the TMP_CLEAN_POLDAILYFININSTBAL. It contains the DUPLICATES of the PolicyDailyFinInstBalance.
PROMPT ======================================================================================================

CREATE TABLE tmp_clean_poldailyfininstbal
AS
  SELECT /*+ parallel(8) */
         *
    FROM (SELECT batch_job.job_id,
                 policy_valuation.oid
                   AS policy_valuation_oid,
                 policy_valuation_inv_values.oid
                   AS pol_val_inv_values_oid,
                 policy_valuation_fininst_dtl.oid
                   AS pol_val_fininst_dtl_oid,
                 --
                 COUNT (*)
                   OVER (PARTITION BY policy_valuation.policy_number, policy_valuation_fininst_dtl.finincial_instrument_oid, policy_valuation_inv_values.valuation_date)
                   AS cnt,
                 --
                 ROW_NUMBER ()
                   OVER (PARTITION BY policy_valuation.policy_number, policy_valuation_fininst_dtl.finincial_instrument_oid, policy_valuation_inv_values.valuation_date
                         ORDER BY batch_job.job_id DESC)
                   AS rn,
                 --
                 policy_valuation.policy_number,
                 policy_valuation_inv_values.valuation_date,
                 --
                 policy_valuation_fininst_dtl.finincial_instrument_cid
                   AS financial_instrument_cid,
                 policy_valuation_fininst_dtl.finincial_instrument_oid
                   AS financial_instrument_oid
            FROM policy_valuation
                 JOIN policy_valuation_configuration ON (policy_valuation_configuration.oid = policy_valuation.configuration_oid)
                 JOIN policy_valuation_inv_values ON (policy_valuation_inv_values.policy_valuation_oid = policy_valuation.oid)
                 JOIN policy_valuation_fininst_dtl ON (policy_valuation_fininst_dtl.pol_val_inv_values_oid = policy_valuation_inv_values.oid)
                 JOIN batch_job ON (batch_job.oid = policy_valuation.batch_job_oid)
           WHERE policy_valuation.valuation_mode_type = 0 AND policy_valuation_configuration.identifier = 'PolicyDailyFinInstBalance')
   WHERE cnt > 1;

PROMPT
PROMPT ========================
PROMPT DELETE the DUPLICATEs
PROMPT ========================

DECLARE
  nb_rows_to_delete   NUMBER;
BEGIN
  SELECT COUNT (*)
    INTO nb_rows_to_delete
    FROM tmp_clean_poldailyfininstbal
   WHERE rn > 1;

  IF nb_rows_to_delete = 0 THEN
    DBMS_OUTPUT.put_line ('No duplicate found !');
  ELSE
    DELETE /*+ parallel(8) */
           FROM policy_valuation_fi_acc_dtl
          WHERE policy_valuation_fi_acc_dtl.policy_valuation_fininst_oid IN (SELECT pol_val_fininst_dtl_oid
                                                                               FROM tmp_clean_poldailyfininstbal
                                                                              WHERE rn > 1);

    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : ' || SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_FI_ACC_DTL');


    DELETE /*+ parallel(8) */
           FROM policy_valuation_gr_acl_dtl
          WHERE policy_valuation_gr_acl_dtl.policy_valuation_fininst_oid IN (SELECT pol_val_fininst_dtl_oid
                                                                               FROM tmp_clean_poldailyfininstbal
                                                                              WHERE rn > 1);

    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : ' || SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_GR_ACL_DTL');

    DELETE /*+ parallel(8) */
           FROM policy_valuation_fininst_dtl
          WHERE     oid IN (SELECT pol_val_fininst_dtl_oid
                              FROM tmp_clean_poldailyfininstbal
                             WHERE rn > 1)
                AND NOT EXISTS
                      (SELECT 1
                         FROM policy_valuation_fi_acc_dtl
                        WHERE policy_valuation_fi_acc_dtl.policy_valuation_fininst_oid = policy_valuation_fininst_dtl.oid)
                AND NOT EXISTS
                      (SELECT 1
                         FROM policy_valuation_gr_acl_dtl
                        WHERE policy_valuation_gr_acl_dtl.policy_valuation_fininst_oid = policy_valuation_fininst_dtl.oid);

    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : ' || SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_FININST_DTL');



    DELETE /*+ parallel(8) */
           FROM policy_valuation_inv_values
          WHERE     oid IN (SELECT pol_val_inv_values_oid
                              FROM tmp_clean_poldailyfininstbal
                             WHERE rn > 1)
                AND NOT EXISTS
                      (SELECT 1
                         FROM policy_valuation_fininst_dtl
                        WHERE policy_valuation_fininst_dtl.pol_val_inv_values_oid = policy_valuation_inv_values.oid);

    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : ' || SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_INV_VALUES');

    DELETE /*+ parallel(8) */
           FROM policy_valuation
          WHERE     oid IN (SELECT policy_valuation_oid
                              FROM tmp_clean_poldailyfininstbal
                             WHERE rn > 1)
                AND NOT EXISTS
                      (SELECT 1
                         FROM policy_valuation_inv_values
                        WHERE policy_valuation_inv_values.policy_valuation_oid = policy_valuation.oid);

    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : ' || SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION');
    --
    COMMIT;
    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : COMMITTED !');
  END IF;
END;
/

SPOOL OFF
EXIT