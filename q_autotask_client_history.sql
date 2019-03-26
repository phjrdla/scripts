set lines 240
col con_id head "Con|tai|ner" form 999
col window_name head "Window" form a16
col wst head "Window|Start|Time" form a12
col window_duration head "Window|Duration|Hours" form 999999
col jobs_created head "Jobs|Created" form 999
col jobs_started head "Jobs|Started" form 999
col jobs_completed head "Jobs|Completed" form 999
col wet head "Window|End|Time" form a12

select 	con_id, window_name, to_char(window_start_time, 'DD-MON HH24:MI') wst,
	extract(hour from window_duration) + round(extract(minute from window_duration)/60) window_duration,
	jobs_created, jobs_started, jobs_completed, 
	to_char(window_end_time, 'DD-MON HH24:MI') wet
from 	cdb_autotask_client_history
where 	client_name = 'auto optimizer stats collection'
order	by window_start_time, con_id
/