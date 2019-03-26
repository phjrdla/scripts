set lines 240
set pages 100
SELECT username, sid, serial#, status, taddr, program
        FROM v$session
		where status = 'ACTIVE'
		and upper(program) like 'RMAN%'
       ORDER BY status,sid,USERNAME;
	   
set pages 0

select 'alter system kill session '||''''||to_char(sid)||','||to_char(serial#)||''''||' immediate;'
        FROM v$session
		where status = 'ACTIVE'
		and upper(program) like 'RMAN%'
       ORDER BY status,sid,USERNAME;
