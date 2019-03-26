column opname format a30 trunc
column username format a20 trunc
set linesize 250
set pages 500

select slo.sid
      ,s.username
	  ,s.sql_id
	  ,s.sql_hash_value
	  ,slo.sql_plan_hash_value
      ,slo.serial#
	  ,slo.opname
	  ,slo.sofar
	  ,slo.totalwork
	  ,slo.time_remaining
	  ,slo.elapsed_seconds 
from v$session_longops slo
    ,v$session s
where slo.sid = s.sid
  and slo.serial# = s.serial#
  and s.status = 'ACTIVE'
  and slo.sql_plan_hash_value > 0
/
