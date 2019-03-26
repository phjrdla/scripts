--In order to get the attribute values of a certain client you can use get_client_attributes procedure
--Get the client name
select 
   client_name 
from 
   dba_autotask_client;
   
declare 
v_service_name varchar2(200);
v_service_name_1 varchar2(200);
v_window       varchar2(20);
v_client_name  varchar2(80);
begin
   v_client_name := 'auto optimizer stats collection';
     dbms_auto_task_admin.get_client_attributes(
      client_name => v_client_name,
      service_name => v_service_name,
      window_group => v_window);

   select decode(v_service_name,NULL,'NULL') into v_service_name_1 from dual;

    dbms_output.put_line(a => 
      ' Attributes for client '||v_client_name||chr(10)||
      ' - Service_Name is: '||v_service_name_1||chr(10)||
      ' - Window Group is: '||v_window);
end;
/