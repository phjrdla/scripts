set lines 240
col con_id head "Con|tai|ner" form 999
col window_name head "window" form a16
col wst head "window|start|time" form a12
col window_duration head "window|dura|tion|hours" form 999999
col job_name head "job name" form a22
col jst head "job|start|time" form a12
col job_duration head "job|dura|tion|mins" form 999999
col job_status head "job|status" form a10
col job_error head "job error" form 99
col job_info head "job info" form a40

select 	con_id, window_name, to_char(window_start_time, 'DD-MON HH24:MI') wst,
	extract(hour from window_duration) + round(extract(minute from window_duration)/60) window_duration,
	job_name, to_char(job_start_time, 'DD-MON HH24:MI') jst, job_status,
	extract(hour from job_duration)*60 + round(extract(minute from job_duration)) job_duration,
	job_error, job_info
from 	cdb_autotask_job_history
where 	client_name = 'auto optimizer stats collection'
order	by job_start_time, con_id
/
