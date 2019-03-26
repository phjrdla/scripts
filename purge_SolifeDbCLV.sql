DELETE 
FROM EXCEPTION_CONTEXT 
WHERE creation_date_time < sysdate - &&1;
COMMIT;

DELETE
FROM batch_exception_context
WHERE batch_job_oid IN
  (SELECT oid
  FROM batch_job
  WHERE batch_job_status_codeid               IN(9,10)
  AND end_date                   < CURRENT_DATE - &&1
  );
COMMIT;

DELETE
FROM batch_job_input
WHERE batch_job_oid IN
  (SELECT oid
  FROM batch_job
  WHERE batch_job_status_codeid               IN(9,10)
  AND end_date                   < CURRENT_DATE - &&1
  );
COMMIT;

DELETE
FROM batch_job_cursor
WHERE batch_job_oid IN
  (SELECT oid
  FROM batch_job
  WHERE batch_job_status_codeid               IN(9,10)
  AND end_date                   < CURRENT_DATE - &&1
  );
COMMIT;

DELETE
FROM batch_job_detail
WHERE batch_job_oid IN
  (SELECT oid
  FROM batch_job
  WHERE batch_job_status_codeid               IN(9,10)
  AND end_date                   < CURRENT_DATE - &&1
  );
COMMIT;

DELETE
FROM batch_job_trace
WHERE batch_job_oid IN
  (SELECT oid
  FROM batch_job
  WHERE batch_job_status_codeid               IN(9,10)
  AND end_date                   < CURRENT_DATE - &&1
  );
COMMIT;

DELETE
FROM batch_job_memo
WHERE batch_job_oid IN
  (SELECT oid
  FROM batch_job
  WHERE batch_job_status_codeid               IN(9,10)
  AND end_date                   < CURRENT_DATE - &&1
  );
COMMIT;

DELETE
FROM batch_job_log
WHERE batch_job_oid IN
  (SELECT oid
  FROM batch_job
  WHERE batch_job_status_codeid               IN(9,10)
  AND end_date                   < CURRENT_DATE - &&1
  );
COMMIT;

DELETE FROM client_notifications WHERE expiry_time < CURRENT_DATE - &&1;
COMMIT;

DELETE
FROM wf_requester_impl
WHERE oid IN
  (SELECT requester_oid
  FROM wf_process_impl
  WHERE (status       = 3
  OR status           = 4
  OR status           = 5)
  AND last_state_time < sysdate - &&1
  );
COMMIT;

DELETE
FROM wf_assignment_impl
WHERE activity_oid IN
  (SELECT oid
  FROM wf_activity_impl
  WHERE process_oid IN
    (SELECT oid
    FROM wf_process_impl
    WHERE (status       = 3
    OR status           = 4
    OR status           = 5)
    AND last_state_time < sysdate - &&1
    )
  );
COMMIT;

DELETE
FROM wf_activity_impl
WHERE process_oid IN
  (SELECT oid
  FROM wf_process_impl
  WHERE (status       = 3
  OR status           = 4
  OR status           = 5)
  AND last_state_time < sysdate - &&1
  );
COMMIT;

DELETE
FROM wf_process_impl
WHERE (status       = 3
OR status           = 4
OR status           = 5)
AND last_state_time < sysdate - &&1;
COMMIT;
