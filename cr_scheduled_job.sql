BEGIN
  dbms_scheduler.create_job(
job_name => 'CLV61PRD.SCHEMASTATS',
job_type => 'PLSQL_BLOCK',
job_action => 'begin
 dbms_stats.gather_schema_stats( USER, degree=>DBMS_STATS.DEFAULT_DEGREE, cascade=>DBMS_STATS.AUTO_CASCADE, options=>''GATHER'', no_invalidate=>False );
end;',
start_date => '10-JUL-2018 12:05:00PM',
repeat_interval => 'FREQ=DAILY',
comments => 'Gather schema stats',
auto_drop => FALSE,
enabled => TRUE
);
  dbms_scheduler.set_attribute(
name => 'CLV61PRD.GATHER_SCHEMA_STATS',
attribute => 'logging_level',
value => DBMS_SCHEDULER.LOGGING_FULL
);
  dbms_scheduler.enable( 'CLV61PRD.SCHEMASTATS' );
END;
/