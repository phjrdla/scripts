SELECT nvl(error_count,-1)
FROM (
select bj.job_id,
SUBSTR(bji.PARAMETER, INSTR(bji.PARAMETER,'<object')+23,
INSTR(bji.PARAMETER,'</object>')-INSTR(bji.PARAMETER,'<object')-23) as policyValuation,
bj.creation_date_time,
bj.modification_date_time,
(bj.modification_date_time - bj.creation_date_time) as duration,
bji.execution_count, bji.error_count
from batch b
inner join batch_job bj on bj.BATCH_OID = b.oid
inner join batch_job_info bji on bj.info_oid = bji.oid
inner join batch_job_input bji on bji.BATCH_JOB_OID = bj.oid
where description = 'Valuation batch'
order by bj.job_id desc
)
WHERE rownum <= 3