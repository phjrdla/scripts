/* 
sessions.sql
Example: @sessions.sql
Copyright @2016 dbaparadise.com
*/     
set linesize 240
set pagesize 100
clear columns
col inst for 99999999
col sid for 9990
col serial# for 999990
col username for a12
col osuser for a16
col program for a10 trunc
col Locked for a6
col status for a1 trunc print
col "hh:mm:ss" for a8
col SQL_ID for a15
col seq# for 99990
col event heading 'Current/LastEvent' for a30 trunc
col state head 'State (sec)' for a14
col module format a30 trunc
col action format a30 trunc

 
select inst_id inst,  sid , serial# , username, 
 ltrim(substr(osuser, greatest(instr(osuser, '\', -1, 1)+1,length(osuser)-14))) osuser,
 substr(program,instr(program,'/',-1)+1,
 decode(instr(program,'@'),0,decode(instr(program,'.'),0,length(program),instr(program,'.')-1), instr(program,'@')-1)) program, 
 decode(lockwait,NULL,' ','L') locked, status, 
to_char(to_date(mod(last_call_et,86400), 'sssss'), 'hh24:mi:ss') "hh:mm:ss",
 SQL_ID, seq# , event, 
decode(state,'WAITING','WAITING '||lpad(to_char(mod(SECONDS_IN_WAIT,86400),'99990'),6),
'WAITED SHORT TIME','ON CPU','WAITED KNOWN TIME','ON CPU',state) state,
 substr(module,1,25) module, substr(action,1,20) action
from GV$SESSION 
where type = 'USER'
and audsid != 0    -- to exclude internal processess
order by inst_id, status, last_call_et desc, sid
/