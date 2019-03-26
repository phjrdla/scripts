set serveroutput on
set echo off
set verify off

define owner=&1
define roleType=&2
define roleName=&3;

declare
dyn_cmd varchar2(1000);
exec_stmt varchar2(1000);
i int;

BEGIN

  i := 0;
  for c1 in (
             select owner||'.'||object_name as fqon
			   from all_objects
			  where object_type in ('TABLE','VIEW')
			    and status = 'VALID'
			    and object_name not in ( 
				                         select table_name
				                           from all_external_tables
										  where owner = upper('&&owner') 
										 union
										 select table_name
										   from all_tables
										  where iot_type is not null
										    and owner = upper('&&owner')
									   )
			    and owner = upper('&&owner')
			  order by object_type, object_name            
            ) loop
				
	-- if i > 10 then
	--   exit;
	-- end if;
			
	if upper('&&roleType') = 'RO' then
	  exec_stmt := 'grant select on '||c1.fqon||' to '||upper('&&roleName');
	elsif upper('&&roleType') = 'RW' then
	  exec_stmt := 'grant select, insert, update, delete on '||c1.fqon||' to '||upper('&&roleName');
	else
	  dbms_output.put_line('Valid role types are RO RW');
	  exit;
    end if;
	
	dbms_output.put_line(exec_stmt);
    execute immediate exec_stmt;
	i := i + 1;
	
  end loop; 
  
  dbms_output.put_line('&&roleType ROLE &&roleName'||' populated by '||to_char(i)||' grants');

END;
/
exit