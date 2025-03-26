set serveroutput on
set verify off

@core\DDL\01_tables\install.sql
@core\DDL\02_types\01_t_credit_data.tps
@core\DDL\02_types\02_t_credit_table.tps
@core\DDL\03_packages\01_user_jobs_pkg.spc
@core\DDL\03_packages\02_user_jobs_pkg.bdy
@core\DDL\03_packages\03_const_pkg.spc
@core\DDL\03_packages\04_process_contracts_pkg.spc
@core\DDL\03_packages\05_process_contracts_pkg.bdy
@core\DML\fill.sql

set echo off
exit 0