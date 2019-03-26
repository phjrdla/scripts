BEGIN
    DBMS_AUTO_TASK_ADMIN.enable(
    client_name => 'sql tuning advisor',
    operation => NULL,
    window_name => 'CUSTOM_WINDOW');
END;
/