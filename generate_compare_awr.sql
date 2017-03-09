define  b_snap_a     = &2;
define  e_snap_a     = &3;
define  b_snap_b     = &5;
define  e_snap_b     = &6;

define dbid_a   =&1;
define dbid_b   =&4;


define report_type='html'
define num_days=0
define top_n_sql=100
define dbid=&dbid_a
define inst_num=1
define begin_snap=&b_snap_a
define end_snap=&e_snap_a
define dbid2=&dbid_b
define inst_num2=1
define num_days2=0
define begin_snap2=&b_snap_b
define end_snap2=&e_snap_b
define report_name=awrrpt_&&dbid._&&inst_num._&&begin_snap._&&end_snap._&&dbid2._&&inst_num2._&&begin_snap2._&&end_snap2..html
@$ORACLE_HOME/rdbms/admin/awrddrpi.sql

define report_type='html'
define num_days=0
define top_n_sql=100
define dbid=&dbid_a
define inst_num=2
define begin_snap=&b_snap_a
define end_snap=&e_snap_a
define dbid2=&dbid_b
define inst_num2=2
define num_days2=0
define begin_snap2=&b_snap_b
define end_snap2=&e_snap_b
define report_name=awrrpt_&&dbid._&&inst_num._&&begin_snap._&&end_snap._&&dbid2._&&inst_num2._&&begin_snap2._&&end_snap2..html
@$ORACLE_HOME/rdbms/admin/awrddrpi.sql

define report_type='html'
define num_days=0
define top_n_sql=100
define dbid=&dbid_a
define begin_snap=&b_snap_a
define end_snap=&e_snap_a
define dbid2=&dbid_b
define num_days2=0
define begin_snap2=&b_snap_b
define end_snap2=&e_snap_b
define instance_numbers_or_all='all'
define instance_numbers_or_all2='all'

define report_name=awrgdrpi_&&dbid._&&begin_snap._&&end_snap._&&dbid2._&&begin_snap2._&&end_snap2..html
@$ORACLE_HOME/rdbms/admin/awrgdrpi.sql

exit

