# plsql-multithread
This is a public repository with an example of multithreading in Oracle Plsql

How does it work?  

Step 1: Run 01_install.sql in your database under the SYS user. If you don't want to create a separate schema, skip this step.
Step 2. Check the connection details in setup.bat. Login and password are already specified, you need the actual SID of the database. If you skipped the previous step, also specify the correct login and password.
Step 3. Run setup.bat.
Step 4. Make sure that there are no invalid objects in the target schema.
Step 5. Run the process_contracts_pkg.run_multithread.