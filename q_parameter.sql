column name format a50 trunc
column value format a120 trunc
set lines 240
set pages 500

select name,value 
from v$parameter
order by 1
/