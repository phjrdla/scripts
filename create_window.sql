BEGIN
    DBMS_SCHEDULER.CREATE_WINDOW (
            window_name => '"SYS"."CUSTOM_WINDOW"',
            resource_plan => '"DEFAULT_MAINTENANCE_PLAN"',
            start_date => NULL,
            repeat_interval => 'FREQ=YEARLY;BYDATE=1017;BYTIME=120000',
            end_date => NULL,
            duration => to_dsinterval('+00 08:00:00.000000'),
            window_priority => 'LOW',
            comments => 'ADHOC window');
END;