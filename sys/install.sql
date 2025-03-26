-- Create the user
create User debt_monitor identified by debt_monitor
    default Tablespace Users
  temporary tablespace temp
      Quota 2000m On Users;

-- Grant/Revoke role privileges 
grant connect to debt_monitor;
grant select_catalog_role to debt_monitor;

-- Grant/Revoke object privileges 
grant execute on DBMS_DESCRIBE to debt_monitor with grant option;
grant execute on DBMS_ISCHED to debt_monitor;
grant execute on DBMS_SCHEDULER to debt_monitor;

-- Grant/Revoke role privileges 
grant connect to debt_monitor;
grant select_catalog_role to debt_monitor;

-- Grant/Revoke system privileges 
grant create job to debt_monitor;
grant create procedure to debt_monitor;
grant create sequence to debt_monitor;
grant create session to debt_monitor;
grant create table to debt_monitor;
grant create trigger to debt_monitor;
grant create type to debt_monitor;
grant create view to debt_monitor;
grant debug connect session to debt_monitor;
grant manage scheduler to debt_monitor;
grant select any dictionary to debt_monitor;
