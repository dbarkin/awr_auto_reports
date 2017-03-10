/*

This SQL select all SQLs ranled by Physical IO, Logical IO, Elapsed Time
Grouped by DBID, INSTANCE_NUMBER,SNAP_ID

Will need to suply DBID, INSTANCE_NUMBER,SNAP_ID

                      s.dbid=1611110930   -- BASELINE CAPACITY RUN DBID CONVERTED
                  and s.instance_number=2 -- BASELINE CAPACITY RUN INSTANCE NUMBER                      
                  and s.snap_id=70246     -- BASELINE CAPACITY RUN 2ND HOUR SNAPSHOT                      
                  and to_date('2016/11/11 10:10:00','YYYY/MM/DD HH24:MI:SS')  between s.begin_interval_time and s.end_interval_time   -- BASELINE CAPACITY RUN 2ND HOUR SNAPSHOT

*/




SELECT sqls_ranked.* 
FROM /* ALL SQLs FROM A SPECIFIC SNAPID RANKED BY PH.IO LOGICAL.IO ELAPSED.MS */ 
(
SELECT sqls_with_metrics.dbid,instance_number,snap_id,begin_interval_time,end_interval_time,sqls_with_metrics.sql_id,sqls_with_metrics.plan_hash_value,
       count_of_plans,
       compute_hash_plan,
       executions, 
       pio_total,pio_per_exec,
       lio_total,lio_per_exec,
       msec_exec_total,msec_per_exec,
       DENSE_RANK() OVER (PARTITION BY sqls_with_metrics.dbid,instance_number,snap_id ORDER BY lio_total DESC NULLS LAST) lio_rank,
       DENSE_RANK() OVER (PARTITION BY sqls_with_metrics.dbid,instance_number,snap_id ORDER BY msec_exec_total DESC NULLS LAST) ela_rank,  
       DENSE_RANK() OVER (PARTITION BY sqls_with_metrics.dbid,instance_number,snap_id ORDER BY pio_total DESC NULLS LAST) pio_rank
       FROM (   /* ALL SQLs FROM A SPECIFIC SNAPID PH.IO LOGICAL.IO ELAPSED.MS */
                SELECT    to_char(min(s.begin_interval_time),'YYYY/MM/DD HH24:MI') begin_interval_time 
                        , to_char(min(s.end_interval_time),'YYYY/MM/DD HH24:MI')   end_interval_time
                        , s.dbid, s.instance_number, s.snap_id, q.sql_id
                        , q.plan_hash_value
                        , count(q.sql_id) over (partition by s.dbid,s.instance_number,s.snap_id,q.sql_id) count_of_plans
                        , sum(q.EXECUTIONS_DELTA) executions
                        , round(sum(DISK_READS_delta),1) pio_total
                        , round(sum(DISK_READS_delta)/greatest(sum(executions_delta),1),1) pio_per_exec
                        , round(sum(BUFFER_GETS_delta),1) lio_total
                        , round(sum(BUFFER_GETS_delta)/greatest(sum(executions_delta),1),1) lio_per_exec
                        , round( sum(ELAPSED_TIME_delta),1) msec_exec_total
                        , round((sum(ELAPSED_TIME_delta)/greatest(sum(executions_delta),1)/1000),5) msec_per_exec
                FROM dba_hist_sqlstat q
                LEFT JOIN dba_hist_snapshot s ON (s.snap_id = q.snap_id and s.dbid = q.dbid and s.instance_number = q.instance_number)
                LEFT JOIN dba_hist_sqltext  t ON (t.sql_id=q.sql_id and t.dbid=q.dbid)                
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
            WHERE sql_plans.dbid=sqls_with_metrics.dbid AND sql_plans.sql_id=sqls_with_metrics.sql_id AND sql_plans.plan_hash_value=sqls_with_metrics.plan_hash_value
) sqls_ranked
where (
lio_rank<=50
OR
ela_rank<=50
      )
