REM generate_local_awr.sql
define dbid_a	   = &1;
define db_name_a   = &2;
define b_snap      = &3;
define e_snap      = &4;

define  num_days     = 1;
define  db_name      = '&db_name_a';
define  dbid         = &dbid_a;

define  begin_snap   = &b_snap;
define  end_snap     = &e_snap;
define  top_n_sql    = 100;
define  inst_num     = 1;
define  report_type  = 'html'
define  report_name  = awrrpt_&&inst_num._&&begin_snap._&&end_snap..html
@?/rdbms/admin/awrrpti.sql

define  num_days     = 0;
define  db_name      = '&db_name_a';
define  dbid         = &dbid_a;

define  begin_snap   = &b_snap;
define  end_snap     = &e_snap;
define  top_n_sql    = 100;
define  inst_num     = 2;
define  report_type  = 'html'
define  report_name  = awrrpt_&&inst_num._&&begin_snap._&&end_snap..html
@?/rdbms/admin/awrrpti.sql


define  num_days     = 0;
define  begin_snap   = &b_snap;
define  end_snap     = &e_snap;
define  top_n_sql    = 100;
define  report_type  = 'html'
define  report_name  = awrgrpt_&&begin_snap._&&end_snap..html
@?/rdbms/admin/awrgrpt.sql

define  num_days     = 0;
define  begin_snap   = &b_snap;
define  end_snap     = &e_snap;
define  top_n_sql    = 100;
define  report_type  = 'text'
define  report_name  = addmrpt_&&begin_snap._&&end_snap..txt
@?/rdbms/admin/addmrpt.sql
exit

