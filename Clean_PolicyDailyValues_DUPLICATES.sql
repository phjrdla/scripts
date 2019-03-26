SET ECHO OFF
SET TIME ON
SET SERVEROUTPUT ON
SET PAGESIZE 1000
SET FEEDBACK OFF

COLUMN TS NEW_VALUE var_ts

SELECT TO_CHAR (SYSDATE, 'yyyy-mm-dd_hh24miss') AS ts FROM DUAL;

SPOOL Clean_PolicyDailyValues_Duplicates_&&VAR_TS..log

ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy-mm-dd hh24:mi:ss';

SELECT SYSDATE FROM DUAL;

SET TIMING ON

PROMPT
PROMPT =============================================================
PROMPT Drop the TMP_CLEAN_POLDAILYVALUES table if it exists
PROMPT =============================================================

BEGIN
  FOR rec IN (SELECT table_name
                FROM user_tables
               WHERE table_name = 'TMP_CLEAN_POLDAILYVALUES') LOOP
    DBMS_OUTPUT.put_line ('Dropping TMP_CLEAN_POLDAILYVALUES table');

    EXECUTE IMMEDIATE 'DROP TABLE TMP_CLEAN_POLDAILYVALUES PURGE';
  END LOOP;
END;
/

PROMPT
PROMPT ======================================================================================================
PROMPT Create the TMP_CLEAN_POLDAILYVALUES. It contains the DUPLICATES of the PolicyDailyValues.
PROMPT ======================================================================================================

CREATE TABLE tmp_clean_poldailyvalues
AS
  SELECT /*+ parallel(8) */
         *
    FROM (SELECT batch_job.job_id,
                 policy_valuation.oid
                   AS policy_valuation_oid,
                 policy_valuation_risk_premium.oid
                   AS pol_val_risk_premium_oid,
                 policy_valuation.policy_number,
                 policy_valuation_risk_premium.coverage_cid,
                 policy_valuation_risk_premium.coverage_oid,
                 policy_valuation_risk_premium.cov_slice_cid,
                 policy_valuation_risk_premium.cov_slice_oid,
                 COUNT (*) OVER (PARTITION BY policy_valuation_risk_premium.coverage_oid, policy_valuation_risk_premium.cov_slice_oid)
                   AS cnt,
                 ROW_NUMBER () OVER (PARTITION BY policy_valuation_risk_premium.coverage_oid, policy_valuation_risk_premium.cov_slice_oid ORDER BY batch_job.job_id DESC)
                   AS rn,
                 policy_valuation_risk_premium.valuation_date,
                 policy_valuation_risk_premium.premium_amount,
                 policy_valuation_risk_premium.annual_premium_amount,
                 policy_valuation_risk_premium.pure_premium
            FROM policy_valuation
                 JOIN policy_valuation_configuration ON (policy_valuation_configuration.oid = policy_valuation.configuration_oid)
                 JOIN policy_valuation_risk_premium ON (policy_valuation_risk_premium.policy_valuation_oid = policy_valuation.oid)
                 JOIN batch_job ON (batch_job.oid = policy_valuation.batch_job_oid)
           WHERE     policy_valuation.valuation_mode_type = 0
                 AND policy_valuation_configuration.identifier = 'PolicyDailyValues'
                 AND policy_valuation_risk_premium.level_type IN (0, 1))
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
    FROM tmp_clean_poldailyvalues
   WHERE rn > 1;

  IF nb_rows_to_delete = 0 THEN
    DBMS_OUTPUT.put_line ('No duplicate found !');
  ELSE
    DELETE /*+ parallel(8) */
           FROM policy_valuation_risk_premium
          WHERE oid IN (SELECT pol_val_risk_premium_oid
                          FROM tmp_clean_poldailyvalues
                         WHERE rn > 1);

    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : ' || SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_RISK_PREMIUM');

    DELETE /*+ parallel(8) */
           FROM policy_valuation
          WHERE     oid IN (SELECT policy_valuation_oid
                              FROM tmp_clean_poldailyvalues
                             WHERE rn > 1)
                AND NOT EXISTS
                      (SELECT 1
                         FROM policy_valuation_risk_premium
                        WHERE policy_valuation_risk_premium.policy_valuation_oid = policy_valuation.oid);

    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : ' || SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION');
  --
  COMMIT;
  DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : COMMITTED !');
  END IF;
END;
/

SPOOL OFF
EXIT