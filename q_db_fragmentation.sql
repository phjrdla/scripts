set lines 170
set pages 10000
col owner format a30
col table_name format a30
col TOTAL_SIZE format 99999999999
col ACTUAL_SIZE format 999999999999
col FRAGMENTED_SPACE format 999999999999
select owner
      ,table_name
      ,blocks
      ,num_rows
      ,avg_row_len
      ,round(((blocks*8/1024)),0) "TOTAL_SIZE"
      ,round((num_rows*avg_row_len/1024/1024),0) "ACTUAL_SIZE"
      ,round(((blocks*8/1024)-(num_rows*avg_row_len/1024/1024)),0) "FRAGMENTED_SPACE" 
from dba_tables 
where owner not in ('SYS','SYSTEM','FDBA','PERFSTAT','DBMON') 
  and round(((blocks*8/1024)-(num_rows*avg_row_len/1024/1024)),2) > 100
order by 8 desc;
