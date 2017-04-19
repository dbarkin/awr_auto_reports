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

REM History 20170413 Added  ENTMAP OFF on plan columns to enable multiline SQLPlans in Excel.


REM define  dbid_1st     = 1611110930;
REM define  instance_1st = 1;
REM define  snap_1st     = 70246;
REM define  dbid_2nd     = 1702091600;
REM define  instance_2nd = 1;
REM define  snap_2nd     = 2655;


set heading on;
set timing off veri off space 1 flush on pause off termout on numwidth 10;
set echo off feedback off pagesize 600 linesize 80 newpage 1 recsep off long 30000;
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
scolumn dbbid      heading "DB Id"     format 9999999999;
column host       heading "Host"      format a12;
column SQL_PLAN        ENTMAP OFF
column SQL_PLAN_FIRST  ENTMAP OFF
column SQL_PLAN_SECOND ENTMAP OFF
column FILENAME        ENTMAP OFF
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
column dbid_1st clear;
prompt Specify instance for 1st run
column instance_1st new_value instance_1st noprint;
select '1st run. Use instance: '||&&instance_1st,nvl(&&instance_1st,9999999999) instance_1st from dual;
column instance_1st clear;

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
column snap_1st clear;

prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Specify DBID for 2nd run
column dbid_2nd new_value dbid_2nd noprint;
select '2nd run. Use DBID: '||&&dbid_2nd,nvl(&&dbid_2nd,9999999999) dbid_2nd from dual;
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
column dbid_2nd clear;
prompt Specify instance for 2nd run
column instance_2nd new_value instance_2nd noprint;
select '2nd run. Use instance: '||&&instance_2nd,nvl(&&instance_2nd,9999999999) instance_2nd from dual;
column instance_2nd clear;

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
column snap_2nd clear;

set termout on;
set linesize 8000;
SET MARKUP HTML ON;
set termout on;
set head on;
column filename new_val filename
select 'diff_rpt_sql_mline_&dbid_1st._'||TRIM('&&snap_1st')||'_&dbid_2nd._'||TRIM('&&snap_2nd')||'.html' filename from dual;
spool &filename
WITH  first as (
select * from SQLS_RANKED
where DBID=&dbid_1st and snap_id=&snap_1st and INSTANCE_NUMBER=&instance_1st),
      second as (
select * from SQLS_RANKED
where DBID=&dbid_2nd and snap_id=&snap_2nd and INSTANCE_NUMBER=&instance_2nd)
select
first.db_name                                     as db_name_1st,
first.host_name                                   as host_name_1st,
first.platform_name                               as platform_name_1st,
first.dbid                                        as dbid_1st,
first.instance_number                             as inst_1st,
first.snap_id                                     as snap_1st,
first.begin_interval_time                         as snap_begin_1st,
first.end_interval_time                           as snap_end_1st,
second.db_name                                    as db_name_2nd,
second.host_name                                  as host_name_2nd,
second.platform_name                              as platform_name_2nd,
second.dbid                                       as dbid_2nd,
second.instance_number                            as inst_2nd,
second.snap_id                                    as snap_2nd,
second.begin_interval_time                        as snap_begin_2nd,
second.end_interval_time                          as snap_end_2nd,
nvl(first.sql_id,second.sql_id)                   as sql_id, 
first.plan_hash_value                             as first_plan_hash_value,
second.plan_hash_value                            as second_plan_hash_value,
decode(first.compute_hash_plan,second.compute_hash_plan,'SAME','DIFFERENT') 
                                                  as compare_plans,
first.total_executions                            as total_executions_1st,
second.total_executions                           as total_executions_2nd,
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
       ) as NUMBER)                               as change_pct_elapsed_time,
first.rank_buffer_gets                            as rank_buffer_gets_1st,
second.rank_buffer_gets                           as rank_buffer_gets_2nd,
first.per_exec_buffer_gets                        as per_exec_buffer_gets_1st,
second.per_exec_buffer_gets                       as per_exec_buffer_gets_2nd,
CAST(DECODE(first.per_exec_buffer_gets,
                              NULL,NULL,
                                 0,NULL,
                                   ROUND(((second.per_exec_buffer_gets-first.per_exec_buffer_gets)/first.per_exec_buffer_gets)*100,1)
       ) as NUMBER)                               as change_pct_exec_buffer_gets,
first.rank_physical_read                          as rank_physical_read_1st,
second.rank_physical_read                         as rank_physical_read_2nd,
first.per_exec_physical_read                      as per_exec_physical_read_1st,
second.per_exec_physical_read                     as per_exec_physical_read_2nd,
CAST(DECODE(first.per_exec_physical_read,
                              NULL,NULL,
                                 0,NULL,
                                   ROUND(((second.per_exec_physical_read-first.per_exec_physical_read)/first.per_exec_physical_read)*100,1)
       ) as NUMBER)                                as change_pct_physical_read,
first.rank_physical_write                          as rank_physical_write_1st,
second.rank_physical_write                         as rank_physical_write_2nd,
first.per_exec_physical_write                      as per_exec_physical_write_1st,
second.per_exec_physical_write                     as per_exec_physical_write_2nd,
CAST(DECODE(first.per_exec_physical_write,
                              NULL,NULL,
                                 0,NULL,
                                   ROUND(((second.per_exec_physical_write-first.per_exec_physical_write)/first.per_exec_physical_write)*100,1)
       ) as NUMBER)                                as change_pct_physical_write,
second.sql_text,
first.sql_plan                                     as sql_plan_first,
second.sql_plan                                    as sql_plan_second,
nvl(second.rank_elapsed_time,first.rank_elapsed_time) 
                                                   as rank_elapsed_time
from first
right outer join second on (first.sql_id=second.sql_id)
order by nvl(second.rank_elapsed_time,first.rank_elapsed_time);
spool off
select 'diff_rpt_sql_sline_&dbid_1st._'||TRIM('&&snap_1st')||'_&dbid_2nd._'||TRIM('&&snap_2nd')||'.html' filename from dual;
spool &filename
WITH  first as (
select * from SQLS_RANKED
where DBID=&dbid_1st and snap_id=&snap_1st and INSTANCE_NUMBER=&instance_1st),
      second as (
select * from SQLS_RANKED
where DBID=&dbid_2nd and snap_id=&snap_2nd and INSTANCE_NUMBER=&instance_2nd)
select
first.db_name                                     as db_name_1st,
first.host_name                                   as host_name_1st,
first.platform_name                               as platform_name_1st,
first.dbid                                        as dbid_1st,
first.instance_number                             as inst_1st,
first.snap_id                                     as snap_1st,
first.begin_interval_time                         as snap_begin_1st,
first.end_interval_time                           as snap_end_1st,
second.db_name                                    as db_name_2nd,
second.host_name                                  as host_name_2nd,
second.platform_name                              as platform_name_2nd,
second.dbid                                       as dbid_2nd,
second.instance_number                            as inst_2nd,
second.snap_id                                    as snap_2nd,
second.begin_interval_time                        as snap_begin_2nd,
second.end_interval_time                          as snap_end_2nd,
nvl(first.sql_id,second.sql_id)                   as sql_id, 
first.plan_hash_value                             as first_plan_hash_value,
second.plan_hash_value                            as second_plan_hash_value,
decode(first.compute_hash_plan,second.compute_hash_plan,'SAME','DIFFERENT') 
                                                  as compare_plans,
first.total_executions                            as total_executions_1st,
second.total_executions                           as total_executions_2nd,
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
       ) as NUMBER)                               as change_pct_elapsed_time,
first.rank_buffer_gets                            as rank_buffer_gets_1st,
second.rank_buffer_gets                           as rank_buffer_gets_2nd,
first.per_exec_buffer_gets                        as per_exec_buffer_gets_1st,
second.per_exec_buffer_gets                       as per_exec_buffer_gets_2nd,
CAST(DECODE(first.per_exec_buffer_gets,
                              NULL,NULL,
                                 0,NULL,
                                   ROUND(((second.per_exec_buffer_gets-first.per_exec_buffer_gets)/first.per_exec_buffer_gets)*100,1)
       ) as NUMBER)                               as change_pct_exec_buffer_gets,
first.rank_physical_read                          as rank_physical_read_1st,
second.rank_physical_read                         as rank_physical_read_2nd,
first.per_exec_physical_read                      as per_exec_physical_read_1st,
second.per_exec_physical_read                     as per_exec_physical_read_2nd,
CAST(DECODE(first.per_exec_physical_read,
                              NULL,NULL,
                                 0,NULL,
                                   ROUND(((second.per_exec_physical_read-first.per_exec_physical_read)/first.per_exec_physical_read)*100,1)
       ) as NUMBER)                                as change_pct_physical_read,
first.rank_physical_write                          as rank_physical_write_1st,
second.rank_physical_write                         as rank_physical_write_2nd,
first.per_exec_physical_write                      as per_exec_physical_write_1st,
second.per_exec_physical_write                     as per_exec_physical_write_2nd,
CAST(DECODE(first.per_exec_physical_write,
                              NULL,NULL,
                                 0,NULL,
                                   ROUND(((second.per_exec_physical_write-first.per_exec_physical_write)/first.per_exec_physical_write)*100,1)
       ) as NUMBER)                                as change_pct_physical_write,
second.sql_text,
nvl(second.rank_elapsed_time,first.rank_elapsed_time) 
                                                   as rank_elapsed_time
from first
right outer join second on (first.sql_id=second.sql_id)
order by nvl(second.rank_elapsed_time,first.rank_elapsed_time);
spool off
select 'diff_rpt_sql_&dbid_1st._'||TRIM('&&snap_1st')||'.html' filename from dual;
spool &filename
WITH  first as (
select * from SQLS_RANKED
where DBID=&dbid_1st and snap_id=&snap_1st and INSTANCE_NUMBER=&instance_1st)
select
first.db_name                       as db_name_1st,
first.host_name                     as host_name_1st,
first.platform_name                 as platform_name_1st,
first.dbid                          as dbid_1st,
first.instance_number               as inst_1st,
first.snap_id                       as snap_1st,
first.begin_interval_time           as snap_begin_1st,
first.end_interval_time             as snap_end_1st,
first.sql_id ,
first.plan_hash_value               as plan_hash_value,
first.total_executions              as total_executions_1st,
first.rank_elapsed_time             as rank_elapsed_time_1st,
first.per_exec_elapsed_time         as per_exec_elapsed_time_1st,
first.total_elapsed_time            as total_elapsed_time_1st,
first.rank_buffer_gets              as rank_buffer_gets_1st,
first.per_exec_buffer_gets          as per_exec_buffer_gets_1st,
first.rank_physical_read            as rank_physical_read_1st,
first.per_exec_physical_read        as per_exec_physical_read_1st,
first.rank_physical_write           as rank_physical_write_1st,
first.per_exec_physical_write       as per_exec_physical_write_1st,
first.sql_text,
first.sql_plan
from first
order by first.rank_elapsed_time;
spool off
select 'diff_rpt_sql_&dbid_2nd._'||TRIM('&&snap_2nd')||'.html' filename from dual;
spool &filename
WITH  first as (
select * from SQLS_RANKED
where DBID=&dbid_2nd and snap_id=&snap_2nd and INSTANCE_NUMBER=&instance_2nd)
select
first.db_name                       as db_name_1st,
first.host_name                     as host_name_1st,
first.platform_name                 as platform_name_1st,
first.dbid                          as dbid_1st,
first.instance_number               as inst_1st,
first.snap_id                       as snap_1st,
first.begin_interval_time           as snap_begin_1st,
first.end_interval_time             as snap_end_1st,
first.sql_id,
first.plan_hash_value               as plan_hash_value,
first.total_executions              as total_executions_1st,
first.rank_elapsed_time             as rank_elapsed_time_1st,
first.per_exec_elapsed_time         as per_exec_elapsed_time_1st,
first.total_elapsed_time            as total_elapsed_time_1st,
first.rank_buffer_gets              as rank_buffer_gets_1st,
first.per_exec_buffer_gets          as per_exec_buffer_gets_1st,
first.rank_physical_read            as rank_physical_read_1st,
first.per_exec_physical_read        as per_exec_physical_read_1st,
first.rank_physical_write           as rank_physical_write_1st,
first.per_exec_physical_write       as per_exec_physical_write_1st,
first.sql_text,
first.sql_plan
from first
order by first.rank_elapsed_time;
spool off
exit
