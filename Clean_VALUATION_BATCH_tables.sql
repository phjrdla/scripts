SET ECHO OFF
SET TIME ON
SET SERVEROUTPUT ON
SET PAGESIZE 1000
SET FEEDBACK OFF
SET LINESIZE 255

SELECT 'Clean_VALUATION_BATCH_Tables 2019-01-04' AS version FROM DUAL;

COLUMN TS NEW_VALUE var_ts

SELECT TO_CHAR (SYSDATE, 'yyyy-mm-dd_hh24miss') AS ts FROM DUAL;

SPOOL Clean_VALUATION_BATCH_tables_&&VAR_TS..log

ALTER SESSION SET NLS_DATE_FORMAT = 'yyyy-mm-dd hh24:mi:ss';

SELECT SYSDATE FROM DUAL;


WHENEVER SQLERROR EXIT FAILURE
SET TIMING ON

PROMPT
PROMPT =============================================================
PROMPT Drop the TMP_CLEAN tables if it exists
PROMPT =============================================================

BEGIN
  FOR rec IN (SELECT table_name
                FROM user_tables
               WHERE table_name IN ('TMP_CLEAN_POLDAILYFININSTBAL', 'TMP_CLEAN_POLDAILYVALUES')) LOOP
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
    FROM (
           SELECT batch_job.job_id,
                  policy_valuation.oid AS policy_valuation_oid,
                  --
                  COUNT (*) OVER (PARTITION BY policy_valuation.policy_number, policy_valuation.valuation_date) AS cnt,
                  --
                  ROW_NUMBER () OVER (PARTITION BY policy_valuation.policy_number, policy_valuation.valuation_date ORDER BY batch_job.job_id DESC) AS rn,
                  --
                  policy_valuation.policy_number,
                  policy_valuation.valuation_date
             FROM policy_valuation
                  JOIN policy_valuation_configuration ON (policy_valuation_configuration.oid = policy_valuation.configuration_oid)
                  JOIN batch_job ON (batch_job.oid = policy_valuation.batch_job_oid)
            WHERE policy_valuation.valuation_mode_type = 0 AND policy_valuation_configuration.identifier = 'PolicyDailyFinInstBalance'
         )
   WHERE cnt > 1;

PROMPT
PROMPT ======================================================================================================
PROMPT Create the TMP_CLEAN_POLDAILYVALUES. It contains the DUPLICATES of the PolicyDailyValues.
PROMPT ======================================================================================================

CREATE TABLE tmp_clean_poldailyvalues
AS
  SELECT /*+ parallel(8) */
         *
    FROM (SELECT batch_job.job_id,
                 policy_valuation.oid AS policy_valuation_oid,
                 policy_valuation_risk_premium.oid AS pol_val_risk_premium_oid,
                 policy_valuation.policy_number,
                 policy_valuation_risk_premium.coverage_cid,
                 policy_valuation_risk_premium.coverage_oid,
                 policy_valuation_risk_premium.cov_slice_cid,
                 policy_valuation_risk_premium.cov_slice_oid,
                 COUNT (*) OVER (PARTITION BY policy_valuation_risk_premium.coverage_oid, policy_valuation_risk_premium.cov_slice_oid) AS cnt,
                 ROW_NUMBER () OVER (PARTITION BY policy_valuation_risk_premium.coverage_oid, policy_valuation_risk_premium.cov_slice_oid ORDER BY batch_job.job_id DESC) AS rn
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
  nb_rows_to_delete_dailyvalues   NUMBER;
  nb_rows_to_delete_fininstbal    NUMBER;
  start_ts                        TIMESTAMP;
  end_ts                          TIMESTAMP;

  FUNCTION format_duration (start_ts TIMESTAMP, end_ts TIMESTAMP)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN    TO_CHAR (EXTRACT (HOUR FROM (end_ts - start_ts)), 'fm00')
           || ':'
           || TO_CHAR (EXTRACT (MINUTE FROM (end_ts - start_ts)), 'fm00')
           || ':'
           || TO_CHAR (EXTRACT (SECOND FROM (end_ts - start_ts)), 'fm00.000');
  END format_duration;
--
BEGIN
  SELECT COUNT (*)
    INTO nb_rows_to_delete_dailyvalues
    FROM tmp_clean_poldailyvalues
   WHERE rn > 1;

  SELECT COUNT (*)
    INTO nb_rows_to_delete_fininstbal
    FROM tmp_clean_poldailyfininstbal
   WHERE rn > 1;

  DBMS_OUTPUT.put_line (nb_rows_to_delete_dailyvalues || ' duplicates found for PolicyDailyValues !');
  DBMS_OUTPUT.put_line (nb_rows_to_delete_fininstbal || ' duplicates found for PolicyDailyFinInstBalance !');


  IF nb_rows_to_delete_dailyvalues = 0 AND nb_rows_to_delete_fininstbal = 0 THEN
    DBMS_OUTPUT.put_line ('No duplicate found !');
  ELSE
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation
          WHERE oid IN (SELECT policy_valuation_oid
                          FROM tmp_clean_poldailyvalues
                         WHERE rn > 1
                        UNION ALL
                        SELECT policy_valuation_oid
                          FROM tmp_clean_poldailyfininstbal
                         WHERE rn > 1);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_inv_values
          WHERE policy_valuation_oid NOT IN (SELECT oid FROM policy_valuation);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_INV_VALUES in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_fininst_dtl
          WHERE pol_val_inv_values_oid NOT IN (SELECT oid FROM policy_valuation_inv_values);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_FININST_DTL in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_fi_acc_dtl
          WHERE policy_valuation_fininst_oid NOT IN (SELECT oid FROM policy_valuation_fininst_dtl);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_FI_ACC_DTL in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_gr_acl_dtl
          WHERE policy_valuation_fininst_oid NOT IN (SELECT oid FROM policy_valuation_fininst_dtl);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_GR_ACL_DTL in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_val_by_slice
          WHERE pol_val_inv_values_oid NOT IN (SELECT oid FROM policy_valuation_inv_values);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_VAL_BY_SLICE in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_flow_by_slice
          WHERE pol_val_inv_values_oid NOT IN (SELECT oid FROM policy_valuation_inv_values);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_FLOW_BY_SLICE in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_risk_capital
          WHERE policy_valuation_oid NOT IN (SELECT oid FROM policy_valuation);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_RISK_CAPITAL in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_other_value
          WHERE policy_val_risk_capital_oid NOT IN (SELECT oid FROM policy_valuation_risk_capital);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_OTHER_VALUE in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_pricing_flow
          WHERE policy_val_risk_capital_oid NOT IN (SELECT oid FROM policy_valuation_risk_capital);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_PRICING_FLOW in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_pricing_risk
          WHERE policy_val_risk_capital_oid NOT IN (SELECT oid FROM policy_valuation_risk_capital);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_PRICING_RISK in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_policy_loan
          WHERE policy_valuation_oid NOT IN (SELECT oid FROM policy_valuation);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_POLICY_LOAN in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_risk_premium
          WHERE policy_valuation_oid NOT IN (SELECT oid FROM policy_valuation);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_RISK_PREMIUM in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_specif_rules
          WHERE policy_valuation_oid NOT IN (SELECT oid FROM policy_valuation);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_SPECIF_RULES in ' || format_duration (start_ts, end_ts));

    -- ---------------------------------
    start_ts   := SYSTIMESTAMP;

    DELETE /*+ parallel */
           FROM policy_valuation_sum_at_risk
          WHERE policy_valuation_oid NOT IN (SELECT oid FROM policy_valuation);

    end_ts     := SYSTIMESTAMP;

    DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows deleted from POLICY_VALUATION_SUM_AT_RISK in ' || format_duration (start_ts, end_ts));

    --
    -- ---------------------------------
    COMMIT;
    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : COMMITED !');
  -- ---------------------------------
  --
  END IF;
--
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : ERROR : exception was raised during DELETE :');
    DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_backtrace ());
    DBMS_OUTPUT.put_line ('------------------------------------------------');
    ROLLBACK;
    DBMS_OUTPUT.put_line (TO_CHAR (SYSDATE, 'HH24:MI:SS') || ' : ROLLBACK done !');

    raise_application_error (-20001, 'DELETE aborted...');
END;
/

PROMPT
PROMPT ======================================================================================================
PROMPT Clean of VALUATION_BATCH tables done !
PROMPT ======================================================================================================

SPOOL OFF
EXIT