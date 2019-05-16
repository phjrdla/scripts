set lines 180 pages 1000
col client_name for a40
col attributes for a60
select client_name, status,attributes,service_name from dba_autotask_client
/
 
BEGIN
  DBMS_AUTO_TASK_ADMIN.disable(
    client_name => 'auto space advisor',
    operation   => NULL,
    window_name => NULL);
END;
/
 
BEGIN
  DBMS_AUTO_TASK_ADMIN.disable(
    client_name => 'sql tuning advisor',
    operation   => NULL,
    window_name => NULL);
END;
/
 
 
select client_name, status,attributes,service_name from dba_autotask_client
/
