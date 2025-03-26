CREATE OR REPLACE PACKAGE user_jobs_pkg AS

  -- этот тип нужен для джобов, не смотри на него, пусть таким и остается
  TYPE t_describe IS RECORD(
     NAME          VARCHAR2(100)
    ,overload      dbms_describe.number_table
    ,position      dbms_describe.number_table
    ,LEVEL         dbms_describe.number_table
    ,argument_name dbms_describe.varchar2_table
    ,datatype      dbms_describe.number_table
    ,default_value dbms_describe.number_table
    ,in_out        dbms_describe.number_table
    ,length        dbms_describe.number_table
    ,PRECISION     dbms_describe.number_table
    ,scale         dbms_describe.number_table
    ,radix         dbms_describe.number_table
    ,spare         dbms_describe.number_table);

  -- создание программы для джоба
  PROCEDURE create_program
  (
    p_program_name   VARCHAR2
   ,p_program_action VARCHAR2
  );
  -- создание самого джоба
  PROCEDURE create_user_job
  (
    p_program_name   VARCHAR2
   ,p_program_action VARCHAR2
   ,p_arguments      IN OUT NOCOPY sys.jobarg_array
   ,p_job_prefix     VARCHAR2 DEFAULT 'JOB$_'
   ,p_debug_mode     BOOLEAN DEFAULT FALSE
   ,p_need_jobno     BOOLEAN DEFAULT FALSE
  );

END user_jobs_pkg;
/
