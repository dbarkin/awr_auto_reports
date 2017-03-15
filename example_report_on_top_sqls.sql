prompt ==========================================================
prompt AWR TOP SQL report will be generated in  'html' format.
prompt You can produced report in Excel an sort by rank columns
prompt If you want to automate report you may set variables before calling this report
prompt ==========================================================
prompt define  dbid_1st     = "DBID of 1st AWR run";
prompt define  snap_1st     = "Use snap id to select SQLs (1st AWR run)";
prompt define  instance_1st = "Instance number (1st AWR run). Should be 1 is single instance";
prompt define  dbid_2nd     = "DBID of second AWR run";
prompt define  snap_2nd     = "Use snap id to select SQLs (2nd AWR run)";
prompt define  instance_2nd = "Instance number (2nd AWR run). Should be 1 is single instance";
prompt ==========================================================
prompt Example: 
prompt define  dbid_1st     = 1611110930;
prompt define  instance_1st = 1;
prompt define  snap_1st     = 70246;
prompt define  dbid_2nd     = 1702091600;
prompt define  instance_2nd = 1;
prompt define  snap_2nd     = 2655;
prompt ==========================================================
REM define  dbid_1st     = 1611110930;
REM define  instance_1st = 1;
REM define  snap_1st     = 70246;
REM define  dbid_2nd     = 1702091600;
REM define  instance_2nd = 1;
REM define  snap_2nd     = 2655;


set heading on;
set timing off veri off space 1 flush on pause off termout on numwidth 10;
set echo off feedback off pagesize 60 linesize 80 newpage 1 recsep off long 30000;
set trimspool on trimout on define "&" concat "." serveroutput on;
set underline on;
clear break compute;
repfooter off;
ttitle off;
btitle off;

set termout on;
column instart_fmt noprint;
column db_name     format a12  heading 'DB Name';
column snap_id     format 99999990 heading 'Snap Id';
column snapdat     format a18  heading 'Snap Started' just c;
column lvl         format 99   heading 'Snap|Level';

set heading off;

column dbb_name   heading "DB Name"   format a12;
column dbbid      heading "DB Id"     format 9999999999;
column host       heading "Host"      format a12;

prompt
prompt
prompt Instances in this Workload Repository schema
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set heading on;
select distinct
       wr.dbid            dbbid
     , wr.instance_number instt_num
     , wr.db_name         dbb_name
     , wr.instance_name   instt_name
     , wr.host_name       host
  from dba_hist_database_instance wr order by db_name,dbid,instance_number;
set heading off;

prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt 1st run is usually baseline against which you will compare 2nd run
prompt AWR Snapshot have required performance metrics to compare SQLs between 1st run and 2nd run
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Specify DBID for 1st run
column dbid_1st new_value dbid_1st noprint;
select '1st run. Use DBID: '||&&dbid_1st,nvl(&&dbid_1st,9999999999) dbid_1st from dual;
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Specify instance for 1st run
column instance_1st new_value instance_1st noprint;
select '1st run. Use instance: '||&&instance_1st,nvl(&&instance_1st,9999999999) instance_1st from dual;

break on inst_name on db_name on host on instart_fmt skip 1;
ttitle off;

select  di.db_name                                        db_name
     , s.snap_id                                         snap_id
     , to_char(max(s.end_interval_time),'dd Mon YYYY HH24:mi') snapdat
     , max(s.snap_level)                                      lvl
  from dba_hist_snapshot s
     , dba_hist_database_instance di
 where di.dbid             = &&dbid_1st
   and di.dbid             = s.dbid
   and di.instance_number  = s.instance_number
   and di.startup_time     = s.startup_time
 group by db_name, snap_id
 order by db_name, snap_id;

prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Specify snapshot id for 1st run
column snap_1st new_value snap_1st noprint;
select '1st run. Use snapshot: '||&&snap_1st,nvl(&&snap_1st,9999999999) snap_1st from dual;

 
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Specify DBID for 2nd run
column dbid_2nd new_value dbid_2nd noprint;
select '2nd run. Use DBID: '||&&dbid_2nd,nvl(&&dbid_2nd,9999999999) dbid_2nd from dual;
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Specify instance for 2nd run
column instance_2nd new_value instance_2nd noprint;
select '2nd run. Use instance: '||&&instance_2nd,nvl(&&instance_2nd,9999999999) instance_2nd from dual;

break on inst_name on db_name on host on instart_fmt skip 1;
ttitle off;

select  di.db_name                                        db_name
     , s.snap_id                                         snap_id
     , to_char(max(s.end_interval_time),'dd Mon YYYY HH24:mi') snapdat
     , max(s.snap_level)                                      lvl
  from dba_hist_snapshot s
     , dba_hist_database_instance di
 where di.dbid             = &&dbid_2nd
   and di.dbid             = s.dbid
   and di.instance_number  = s.instance_number
   and di.startup_time     = s.startup_time
 group by db_name, snap_id
 order by db_name, snap_id;
 

prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Specify snapshot id for 2nd run
column snap_2nd new_value snap_2nd noprint;
select '2nd run. Use snapshot: '||&&snap_2nd,nvl(&&snap_2nd,9999999999) snap_2nd from dual;

set termout on;
set linesize 8000;
SET MARKUP HTML ON;
set termout on;
set head on;
spool report_top_sql.html;

WITH  first as (
select * from SQLS_RANKED
where DBID=&dbid_1st and snap_id=&snap_1st and INSTANCE_NUMBER=&instance_1st),
      second as (
select * from SQLS_RANKED
where DBID=&dbid_2nd and snap_id=&snap_2nd and INSTANCE_NUMBER=&instance_2nd)
select nvl(first.sql_id,second.sql_id) as sql_id , first.plan_hash_value as first_plan_hash_value,
decode(first.compute_hash_plan,second.compute_hash_plan,'SAME','DIFFERENT') compare_plans,
first.total_executions                         as total_executions_1st,
second.total_executions                        as total_executions_2nd,
first.rank_elapsed_time                           as rank_elapsed_time_1st, 
second.rank_elapsed_time                          as rank_elapsed_time_2nd,
first.per_exec_elapsed_time                       as per_exec_elapsed_time_1st,
second.per_exec_elapsed_time                      as per_exec_elapsed_time_2nd,
first.total_elapsed_time                          as total_elapsed_time_1st,
second.total_elapsed_time                         as total_elapsed_time_2nd,
CAST(DECODE(first.per_exec_elapsed_time,
                              NULL,NULL,
                                 0,NULL,
                                   ROUND(((second.per_exec_elapsed_time-first.per_exec_elapsed_time)/first.per_exec_elapsed_time)*100,1)
       ) as NUMBER) change_pct_elapsed_time,
first.rank_buffer_gets                           as rank_buffer_gets_1st, 
second.rank_buffer_gets                          as rank_buffer_gets_2nd,
first.per_exec_buffer_gets                        as per_exec_buffer_gets_1st,
second.per_exec_buffer_gets                       as per_exec_buffer_gets_2nd,
CAST(DECODE(first.per_exec_buffer_gets,
                              NULL,NULL,
                                 0,NULL,
                                   ROUND(((second.per_exec_buffer_gets-first.per_exec_buffer_gets)/first.per_exec_buffer_gets)*100,1)
       ) as NUMBER) change_pct_exec_buffer_gets,
first.rank_physical_read                          as rank_physical_read_1st, 
second.rank_physical_read                         as rank_physical_read_2nd,
first.per_exec_physical_read                      as per_exec_physical_read_1st,
second.per_exec_physical_read                     as per_exec_physical_read_2nd,
CAST(DECODE(first.per_exec_physical_read,
                              NULL,NULL,
                                 0,NULL,
                                   ROUND(((second.per_exec_physical_read-first.per_exec_physical_read)/first.per_exec_physical_read)*100,1)    
       ) as NUMBER) change_pct_physical_read,
first.rank_physical_write                          as rank_physical_write_1st, 
second.rank_physical_write                         as rank_physical_write_2nd,
first.per_exec_physical_write                      as per_exec_physical_write_1st,
second.per_exec_physical_write                     as per_exec_physical_write_2nd,
CAST(DECODE(first.per_exec_physical_write,
                              NULL,NULL,
                                 0,NULL,
                                   ROUND(((second.per_exec_physical_write-first.per_exec_physical_write)/first.per_exec_physical_write)*100,1) 
       ) as NUMBER) change_pct_physical_write,
second.plan_hash_value as second_plan_hash_value,
second.sql_text,
nvl(second.rank_elapsed_time,first.rank_elapsed_time) rank_elapsed_time        
from first
right outer join second on (first.sql_id=second.sql_id)
order by nvl(second.rank_elapsed_time,first.rank_elapsed_time);
spool off 
exit