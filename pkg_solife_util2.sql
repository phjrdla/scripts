/*
Package usage
kills Oracle user sessions
lock authorized application users ( set locked to 1 in abstract_principal for users having locked=0 except OPCON
unlock authorized users by restoring abstract_principal to previous state

author  : bip
date    : 13-APR-18

*/
create or replace package solife_util2 as
  procedure killSessions ( doit boolean default false ) ;
  procedure save_table( schema varchar2, table2save varchar2, tablebackup varchar2, doit boolean default false );
  procedure lockUsers( schema varchar2, schemas2exclude varchar2, doit boolean default false );
  procedure unlockUsers( schema varchar2, doit boolean default false );
end solife_util2;
/
create or replace package body solife_util2 as
  procedure display_mode(doit boolean) is
    begin
      if doit then
        dbms_output.put_line(chr(10)||'***************** LIVE *************************');
      else
        dbms_output.put_line(chr(10)||'***************** SIMULATION *************************');
      end if;
  end display_mode;
  
  function notinlist ( schemas varchar2 ) 
    return varchar2 
  is
  notinlist varchar2(200);
  begin
    notinlist := replace(schemas, ' ', '');
    notinlist := replace(notinlist, ':', ''',''');
    notinlist := '''' || notinlist || '''';
    return upper(notinlist);
  end;

  procedure save_table( schema varchar2, table2save varchar2, tablebackup varchar2, doit boolean default false ) is
    -- makes a copy of a table owned by a schema
    stmt     varchar2(2000);
    c_names  sys_refcursor;
    v_code   NUMBER;
    v_errm   VARCHAR2(64);
    cnt      integer := 0;

    begin
      stmt := 'select count(1)'||
              '  from dba_tables'||
              ' where owner = '||''''||upper(schema)||''''||
              '   and table_name = '||''''||upper(tablebackup)||'''';
      
      -- check if backup table there  
      dbms_output.put_line(stmt);
      if doit then
        execute immediate stmt into cnt;
      end if;
      dbms_output.put_line('cnt is '||to_char(cnt));
      if  cnt = 0  then
        stmt := 'create table '||schema||'.'||tablebackup||' as '||
                '  select * from '||schema||'.'||table2save;
        display_mode(doit);
        dbms_output.put_line(stmt);
        if doit then
          execute immediate stmt;
        end if;
      else
        stmt := 'truncate table '||schema||'.'||tablebackup;
        display_mode(doit);
        dbms_output.put_line(stmt);
        if doit then
          execute immediate stmt;
        end if;
        stmt := 'insert into '||schema||'.'||tablebackup||' select * from '||schema||'.'||table2save;
        display_mode(doit);
        dbms_output.put_line(stmt);
        if doit then
          execute immediate stmt;
        end if;
      end if;
      
      exception
         when others then
           v_code := SQLCODE;
           v_errm := SUBSTR(SQLERRM, 1, 64);
           DBMS_OUTPUT.PUT_LINE('Error code ' || v_code || ': ' || v_errm);
          raise;
    end save_table;
  
  procedure abstract_principal_users( schema varchar2, action varchar2, schemas2exclude varchar2, doit boolean default false ) is
    -- lock accounts authorised in abstract_principal by setting locked = 0 except for OPCON
    table2save  varchar2(30) := 'ABSTRACT_PRINCIPAL';
    tablebackup varchar2(30) := 'ABSTRACT_PRINCIPAL_SAVE';
	tablelocked varchar2(30) := 'ABSTRACT_PRINCIPAL_LOCKED';
    stmt        varchar2(2000);
	notinclause varchar2(200);
    v_code      NUMBER;
    v_errm      VARCHAR2(64);
 
    begin
      if upper(action) = 'LOCK' then
        -- block all opened accounts except opcon
        -- save ABSTRACT_PRINCIPAL
        save_table( schema, table2save, tablebackup, doit );
		
		-- build not in list
		dbms_output.put_line('schemas2exclude is '||schemas2exclude);
		notinclause := notinlist(schemas2exclude);

        -- update abstract_principal
        stmt := 'update '||schema||'.'||table2save||
                  ' set locked = 1'||
                ' where nvl(locked,0) = 0'||
                  ' and name not in ('||notinclause||')';
        
        display_mode(doit);
        dbms_output.put_line(stmt);
        if doit then
          execute immediate stmt;
          execute immediate 'commit';
        end if;
		
		-- save ABSTRACT_PRINCIPAL after locking
		-- save_table( schema, table2save, tablelocked, doit );
           
      elsif upper(action) = 'UNLOCK' then
        -- restore original state of abstract_principal
        stmt := 'update '||schema||'.'||table2save||' a'||
                '   set locked = ( select b.locked'||
                                   ' from '||schema||'.'||tablebackup||' b'||
                                  ' where b.oid = a.oid'||
                                    ' and nvl(b.locked,0) = 0 )'||
                ' where exists ( select 1'||
                '  from '||schema||'.'||tablebackup||' c'||
                ' where c.oid = a.oid'||
                  ' and nvl(c.locked,0) = 0 )';
                
        display_mode(doit);
        dbms_output.put_line(stmt);
        if doit then
          execute immediate stmt;
          execute immediate 'commit';
        end if;
        
      else
        dbms_output.put_line('Action is LOCK or UNLOCK not '||action||' exit');
        return;
      end if;
          
      exception
        when others then
          v_code := SQLCODE;
          v_errm := SUBSTR(SQLERRM, 1, 64);
          DBMS_OUTPUT.PUT_LINE('Error code ' || v_code || ': ' || v_errm);
          raise;
    end abstract_principal_users;
  
  procedure lockUsers( schema varchar2, schemas2exclude varchar2, doit boolean default false ) is
  begin
     sys.dbms_system.ksdwrt(3,'lockUsers starts');
     abstract_principal_users( schema, 'LOCK', schemas2exclude, doit );
     sys.dbms_system.ksdwrt(3,'lockUsers ended');
  end lockUsers;
  
  procedure unlockUsers( schema varchar2, doit boolean default false ) is
  begin
     sys.dbms_system.ksdwrt(3,'unlockUsers starts');
     abstract_principal_users( schema, 'UNLOCK', '', doit );
     sys.dbms_system.ksdwrt(3,'unlockUsers ended');
  end unlockUsers;
  
  procedure killSessions ( doit boolean default false ) is
    /*
    Kills all user sessions except SYS SYSTEM DBSNMP OPCON OPCONAP
    Enables restricted mode on database
    */
    c_username v$session.username%type; 
    c_sid      v$session.sid%type; 
    c_serial   v$session.serial#%type;
    c_status   v$session.status%type;
    c_taddr    v$session.taddr%type;
    cmd        varchar2(80);
    msg        varchar2(80);
    username   varchar2(30);
    cnt        integer;
    sessn      integer := 0;
    sesskilled integer := 0;
    v_code     NUMBER;
    v_errm     VARCHAR2(64);
  
    CURSOR c_sessions is 
      SELECT username, sid, serial#, status, taddr
        FROM v$session
       WHERE username not in ('SYS','SYSTEM','DBSNMP','OPCON','OPCONAP','SQLODSUSE','ORAPRDADM')
       ORDER BY USERNAME; 
      
    begin 
      -- Current number of sessions 
      execute immediate 'select count(1) from v$session ' into cnt;
      dbms_output.put_line('Current number of sessions is '||to_char(cnt));
           
      -- List and kill sessions
      sys.dbms_system.ksdwrt(3,'killSessions starts');
      OPEN c_sessions; 
        LOOP 
          FETCH c_sessions into c_username, c_sid, c_serial, c_status, c_taddr; 
          EXIT WHEN c_sessions%notfound; 
        
          -- Session being processed
          sessn := sessn + 1;
          dbms_output.put_line('Session '||to_char(sessn)||' : User is '||c_username||' session status is '||c_status );
       
          -- Warning if session involved in a transaction
          if  c_taddr is not null then 
            dbms_output.put_line('A transaction is still running, will complete before session is terminated');
          else
            dbms_output.put_line('Session is clean');
          end if;
      
          cmd := 'alter system kill session '||''''||to_char(c_sid)||','||to_char(c_serial)||''' immediate';
          display_mode(doit);
          dbms_output.put_line(cmd);
          if doit then
            -------------------------------------------------------
            -- handle sessions already gone
            BEGIN
            execute immediate cmd;
            exception
                when others then
				  -- ORA-00030: User session ID does not exist
                  if SQLCODE = -30 then
                    continue; -- suppreses ORA-00030 exception
				  -- ORA-00031: User session marked for kill
				  elsif SQLCODE = -31 then
				    continue; -- suppreses ORA-00031 exception
                  else
                    v_code := SQLCODE;
                    v_errm := SUBSTR(SQLERRM, 1, 64);
                    DBMS_OUTPUT.PUT_LINE('Error code ' || v_code || ': ' || v_errm);
                    raise;
                end if;  
            END;
            -------------------------------------------------------
            sesskilled := sesskilled + 1;
            msg := 'Session '||''''||to_char(c_sid)||','||to_char(c_serial)||''' for '||c_username||' was terminated';
            dbms_output.put_line(msg);
          end if;
        END LOOP;
      CLOSE c_sessions;
      sys.dbms_system.ksdwrt(3,'killSessions ended');
   
      -- After killing sessions
      display_mode(doit);
      execute immediate 'select count(1) from v$session ' into cnt;
      dbms_output.put_line('Remaining number of sessions is '||to_char(cnt));
      if doit then
        dbms_output.put_line(to_char(sesskilled)||' sessions were killed');
      end if;
    
     exception
        when others then
          v_code := SQLCODE;
          v_errm := SUBSTR(SQLERRM, 1, 64);
          DBMS_OUTPUT.PUT_LINE('Error code ' || v_code || ': ' || v_errm);
         raise;
  end killSessions;

end solife_util2;
/

