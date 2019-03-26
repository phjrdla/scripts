set lines 240
set pages 0
set trimspool on
set feedback off
set heading off

spool cr_resizeTS.txt
select 'set echo on ' 
  from dual
/
select 'set timing on'
  from dual
/
select 'alter database datafile'||' '''||file_name||''''||' resize '||round(highwater+2)||'M'||';' 
  from ( select a.tablespace_name
               ,a.file_name
               ,a.bytes/1024/1024 file_size_MB
               ,(b.maximum+c.blocks-1)*d.db_block_size/(1024*1024) highwater
          from dba_data_files a
             ,(select file_id,max(block_id) maximum
                 from dba_extents
                group by file_id) b
              ,dba_extents c
             ,(select value db_block_size
                 from v$parameter
                where name='db_block_size') d
 where a.file_id=  b.file_id
   and   c.file_id  = b.file_id
   and   c.block_id = b.maximum
 order by a.tablespace_name,a.file_name)
/
spool off
