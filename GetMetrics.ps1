<#	
.SYNOPSIS
CollectMetrics collects metrics from v$sysmetric_history

.DESCRIPTION
GetMetrics dumps selected metrics from v$sysmetric_history  

.Parameter connectStr
SQL*NET connect string. Mandatory.

.Example 
CollectMetrics -connectStr orlsol00_prm
#>

[CmdletBinding()] param(
 [Parameter(Mandatory=$True) ] [string]$connectStr
)

##########################################################################################################
function GetMetrics {
  param( $cnx )

  $thisFunction = '{0}' -f $MyInvocation.MyCommand
#write-output "`nThis is function $thisFunction"
#write-output '`nCollects metrics from v$sysmetric_history'

  $sql = @"
set lines 350
set pages 0
set heading off
set feedback off
set trimspool on

column "BEGINTIME"     format a19 trunc
column "HOSTCUPSEC"    format 099999.999
column "HOSTCUPCT"     format 099.999
column "CUPSEC"        format 0999.999
column "DBCPUTIMRATIO" format 0999.999
column "AVGACTSESS"    format 0999
column "SESSCNT"       format 0999
column "LOAD"          format 099.999
column "EXECPSEC"      format 09999
column "EXECPTXN"      format 09999
column "EXECPUSERCALL" format 09999
column "RESPTPTXN"     format 099.999
column "SQLRESPT"      format 099.999
column "USERCALLSPSEC" format 09999
column "USERCALLSPTXN" format 09999
column "USERTXNPSEC"   format 09999
column "SHRFREEPCT"    format 099.999
column "ENQRPTXN"      format 09999
column "DBBCHNGPTXN"   format 09999999
column "REDOPSEC_MB"   format 0999.99
column "REDOPTXN_MB"   format 0999.99
column "PARSEPTXN"     format 09999


select 'BEGINTIME,HOSTCUPSEC,HOSTCUPCT,CUPSEC,DBCPUTIMRATIO, AVGACTSESS,SESSCNT,LOAD,EXECPSEC,EXECPTXN,EXECPUSERCALL,RESPTPTXN,SQLRESPT,USERCALLSPSEC,USERCALLSPTXN,USERTXNPSEC,SHRFREEPCT,ENQRPTXN,DBBCHNGPTXN,REDOPSEC_MB,REDOPTXN_MB,PARSEPTXN' "metrics"
  from dual
/
select to_char(begin_time, 'YYYY-MM-DD HH24:MI:SS')                                          "BEGINTIME", ','
      ,round( sum ( decode( metric_name, 'Host CPU Usage Per Sec', value/100) ), 3 )         "HOSTCUPSEC",  ','  
	  ,round( sum ( decode( metric_name, 'Host CPU Utilization (%)', value) ), 3 )           "HOSTCUPCT", ',' 
	  ,round( sum ( decode( metric_name, 'CPU Usage Per Sec', value/100) ), 3 )              "CUPSEC", ','
	  ,round( sum ( decode( metric_name, 'Database CPU Time Ratio', value) ), 2 )            "DBCPUTIMRATIO", ','
	  ,round( sum ( decode( metric_name, 'Average Active Sessions', value) ) )               "AVGACTSESS", ','
      ,round( sum ( decode( metric_name, 'Session Count', value) ) )                         "SESSCNT", ','
	  ,round( sum ( decode( metric_name, 'Current OS Load', value) ) )                       "LOAD", ','
	  ,round( sum ( decode( metric_name, 'Executions Per Sec', value) ) )                    "EXECPSEC", ','
      ,round( sum ( decode( metric_name, 'Executions Per Txn', value) ) )                    "EXECPTXN", ','
      ,round( sum ( decode( metric_name, 'Executions Per User Call', value) ) )              "EXECPUSERCALL", ','
	  ,round( sum ( decode( metric_name, 'Response Time Per Txn', value/100) ), 3 )          "RESPTPTXN" , ','
	  ,round( sum ( decode( metric_name, 'SQL Service Response Time', value/100) ), 3 )      "SQLRESPT" , ','
	  ,round( sum ( decode( metric_name, 'User Calls Per Sec', value) ) )                    "USERCALLSPSEC" , ','
      ,round( sum ( decode( metric_name, 'User Calls Per Txn', value) ) )                    "USERCALLSPTXN" , ','
	  ,round( sum ( decode( metric_name, 'User Transaction Per Sec', value) ) )              "USERTXNPSEC" , ','
	  ,round( sum ( decode( metric_name, 'Shared Pool Free %', value) ), 3 )                 "SHRFREEPCT" , ','
	  ,round( sum ( decode( metric_name, 'Enqueue Requests Per Txn', value) ) )              "ENQRPTXN" , ','
	  ,round( sum ( decode( metric_name, 'DB Block Changes Per Txn', value) ) )              "DBBCHNGPTXN" , ','
	  ,round( sum ( decode( metric_name, 'Redo Generated Per Sec', value/(1024*1024)) ), 3 ) "REDOPSEC_MB" , ','
	  ,round( sum ( decode( metric_name, 'Redo Generated Per Txn', value/(1024*1024)) ), 3 ) "REDOPTXN_MB" , ','
	  ,round( sum ( decode( metric_name, 'Total Parse Count Per Txn', value) ) )             "PARSEPTXN"
 from v`$sysmetric_history
where group_id = 2
group by to_char(begin_time,'YYYY-MM-DD HH24:MI:SS') 
		,to_char(end_time, 'YYYY-MM-DD HH24:MI:SS')
order by to_char(begin_time,'YYYY-MM-DD HH24:MI:SS')
/
"@
  $sql | sqlplus -S $cnx
}

$cnx            = "bip/Koek1081@$connectStr"
$tstamp         = get-date -Format 'yyyyMMddTHHmm'
$metricFileName = 'c:\temp\sysmetric_history' + '_' + "$tstamp" + '.csv'

GetMetrics $cnx | Out-File $metricFileName  -encoding ascii
