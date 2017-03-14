/*
following privileges have to be granted to user

grant select on dba_hist_sqlstat to dbarkin;
grant select on dba_hist_snapshot to dbarkin;
grant select on dba_hist_sqltext  to dbarkin;
grant select on dba_hist_sql_plan to dbarkin;


This SQL select all SQLs ranled by Physical IO, Logical IO, Elapsed Time
Grouped by DBID, INSTANCE_NUMBER,SNAP_ID

Will need to suply DBID, INSTANCE_NUMBER,SNAP_ID

                      s.dbid=1611110930   -- BASELINE CAPACITY RUN DBID CONVERTED
                  and s.instance_number=2 -- BASELINE CAPACITY RUN INSTANCE NUMBER                      
                  and s.snap_id=70246     -- BASELINE CAPACITY RUN 2ND HOUR SNAPSHOT                      
                  and to_date('2016/11/11 10:10:00','YYYY/MM/DD HH24:MI:SS')  between s.begin_interval_time and s.end_interval_time   -- BASELINE CAPACITY RUN 2ND HOUR SNAPSHOT

*/

CREATE OR REPLACE VIEW SQLS_RANKED AS
SELECT sqls_ranked.*, sql_text.sql_text
FROM /* ALL SQLs FROM A SPECIFIC SNAPID RANKED BY PH.IO LOGICAL.IO ELAPSED.MS */ 
(
SELECT sqls_with_metrics.dbid,instance_number,snap_id,begin_interval_time,end_interval_time,sqls_with_metrics.sql_id,sqls_with_metrics.plan_hash_value,
       count_of_plans,
       compute_hash_plan,
       total_executions, 
       total_physical_read, per_exec_physical_read,
       total_physical_write,per_exec_physical_write,
       total_buffer_gets,   per_exec_buffer_gets,
       total_elapsed_time,  per_exec_elapsed_time,
       total_px_servers,    per_exec_px_servers,
       DENSE_RANK() OVER (PARTITION BY sqls_with_metrics.dbid,instance_number,snap_id ORDER BY total_buffer_gets DESC NULLS LAST) rank_buffer_gets,
       DENSE_RANK() OVER (PARTITION BY sqls_with_metrics.dbid,instance_number,snap_id ORDER BY total_elapsed_time DESC NULLS LAST) rank_elapsed_time,  
       DENSE_RANK() OVER (PARTITION BY sqls_with_metrics.dbid,instance_number,snap_id ORDER BY total_physical_read DESC NULLS LAST) rank_physical_read,
       DENSE_RANK() OVER (PARTITION BY sqls_with_metrics.dbid,instance_number,snap_id ORDER BY total_physical_write DESC NULLS LAST) rank_physical_write       
       FROM (   /* ALL SQLs FROM A SPECIFIC SNAPID PH.IO LOGICAL.IO ELAPSED.MS */
                SELECT    to_char(min(s.begin_interval_time),'YYYY/MM/DD HH24:MI') begin_interval_time 
                        , to_char(min(s.end_interval_time),'YYYY/MM/DD HH24:MI')   end_interval_time
                        , s.dbid, s.instance_number, s.snap_id, q.sql_id
                        , q.plan_hash_value
                        , count(q.sql_id) over (partition by s.dbid,s.instance_number,s.snap_id,q.sql_id) count_of_plans
                        , sum(q.EXECUTIONS_DELTA) total_executions
                        , round(sum(PHYSICAL_READ_REQUESTS_DELTA),1) total_physical_read
                        , round(sum(PHYSICAL_READ_REQUESTS_DELTA)/greatest(sum(executions_delta),1),1) per_exec_physical_read
                        , round(sum(PHYSICAL_WRITE_REQUESTS_DELTA),1) total_physical_write
                        , round(sum(PHYSICAL_WRITE_REQUESTS_DELTA)/greatest(sum(executions_delta),1),1) per_exec_physical_write
                        , round(sum(PX_SERVERS_EXECS_DELTA),1) total_px_servers
                        , round(sum(PX_SERVERS_EXECS_DELTA)/greatest(sum(executions_delta),1),1) per_exec_px_servers
                        , round(sum(BUFFER_GETS_delta),1) total_buffer_gets
                        , round(sum(BUFFER_GETS_delta)/greatest(sum(executions_delta),1),1) per_exec_buffer_gets
                        , round(sum(ELAPSED_TIME_delta),1/1000) total_elapsed_time
                        , round((sum(ELAPSED_TIME_delta)/greatest(sum(executions_delta),1)/1000),5) per_exec_elapsed_time
                FROM dba_hist_sqlstat q
                LEFT JOIN dba_hist_snapshot s ON (s.snap_id = q.snap_id and s.dbid = q.dbid and s.instance_number = q.instance_number)
                WHERE 
                      plan_hash_value<>0
                  and q.parsing_schema_name<>'SYS'
                GROUP BY s.dbid, s.instance_number,s.snap_id, q.sql_id, q.plan_hash_value
            ) sqls_with_metrics,
            ( /* ALL SQL PLANS HASHED */
               SELECT dbid,sql_id,plan_hash_value,
                      standard_hash(listagg(id||operation||options||object_name) 
                      within group (order by id,operation,options,object_name)) as compute_hash_plan
               FROM dba_hist_sql_plan 
               GROUP BY dbid,sql_id,plan_hash_value
            ) sql_plans
            WHERE 
                sql_plans.dbid=sqls_with_metrics.dbid 
            AND sql_plans.sql_id=sqls_with_metrics.sql_id 
            AND sql_plans.plan_hash_value=sqls_with_metrics.plan_hash_value
) sqls_ranked
full join dba_hist_sqltext sql_text on (sql_text.sql_id=sqls_ranked.sql_id and sql_text.dbid=sqls_ranked.dbid)     
where (
rank_buffer_gets<=50
OR
rank_elapsed_time<=50
)
WITH READ ONLY;