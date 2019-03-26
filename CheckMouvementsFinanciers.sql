SET FEEDBACK OFF

SET SERVEROUTPUT ON

DECLARE
    cnt      NUMBER(9,0);
    v_code   NUMBER;
    v_errm   VARCHAR2(64);
BEGIN
    SELECT
        COUNT(DISTINCT s.oid)
    INTO cnt
    FROM
        movement m
        INNER JOIN accounting_transaction at 
          ON m.accounting_transaction_oid = at.oid
        INNER JOIN sub_position sp 
          ON m.sub_position_oid = sp.oid
        INNER JOIN securities s 
          ON s.oid = m.securities_target_oid
        INNER JOIN external_account ea 
          ON ea.owner_oid = s.oid
        INNER JOIN identifier i 
          ON i.securities_oid = s.oid AND nature = 31
        INNER JOIN sub_position_type spt 
          ON sp.subposition_type_codeid = spt.codeid
        INNER JOIN currency c 
          ON m.currency_oid = c.oid
    WHERE
        spt.external_id = 'TRANSFER_TO_EXECUTE'
        AND at.transaction_number LIKE '%TRANSFER%'
        AND ea.intern_account_oid IS NULL;

    dbms_output.put_line(cnt);
EXCEPTION
    WHEN OTHERS THEN
        v_code := sqlcode;
        v_errm := substr(sqlerrm,1,64);
        dbms_output.put_line('Error code '
                               || v_code
                               || ': '
                               || v_errm);
        RAISE;
END;
/