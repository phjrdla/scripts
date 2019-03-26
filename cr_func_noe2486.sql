create or replace function noe2486 ( error_count_max number )
  return number
as
  code90 number := 90;
  stmt varchar2(4000);
  error_count_sum number;
  v_code   NUMBER;
  v_errm   VARCHAR2(64);

begin
  stmt := 'SELECT sum(error_count)'||
          '  FROM (select bj.job_id,'||
          '               SUBSTR(bji.PARAMETER, INSTR(bji.PARAMETER,''<object'')+23,'||
          '               INSTR(bji.PARAMETER,''</object>'')-INSTR(bji.PARAMETER,''<object'')-23) as policyValuation,'||
          '               bj.creation_date_time,'||
          '               bj.modification_date_time,'||
          '              (bj.modification_date_time - bj.creation_date_time) as duration,'||
          '               bji.execution_count, bji.error_count'||
          '          from batch b'||
          '               inner join batch_job bj on bj.BATCH_OID = b.oid'||
          '               inner join batch_job_info bji on bj.info_oid = bji.oid'||
          '               inner join batch_job_input bji on bji.BATCH_JOB_OID = bj.oid'||
          '               where description = ''Valuation batch'''||
          '         order by bj.job_id desc)'||
          '         WHERE rownum <= 3';
    
    execute immediate stmt into error_count_sum;
    -- dbms_output.put_line('error_count_sum is '||to_char(error_count_sum));
    if error_count_sum >= error_count_max then
      return 90;
    else
      return 0;
    end if;
    
    exception
      when others then
        v_code := SQLCODE;
        v_errm := SUBSTR(SQLERRM, 1, 64);
        DBMS_OUTPUT.PUT_LINE('Error code ' || v_code || ': ' || v_errm);
        raise;
end;
/