define  dbid_1st     = 1611110930;
define  snap_1st     = 70246;
define  dbid_2nd     = 1702091600;
define  snap_2nd     = 2655;

WITH  first as (
select * from SQLS_RANKED
where DBID=&dbid_1st and snap_id=&snap_1st and INSTANCE_NUMBER=1),
      second as (
select * from SQLS_RANKED
where DBID=&dbid_2nd and snap_id=&snap_2nd and INSTANCE_NUMBER=1)
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
