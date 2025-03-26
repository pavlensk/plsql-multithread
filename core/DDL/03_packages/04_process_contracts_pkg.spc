CREATE OR REPLACE PACKAGE process_contracts_pkg AS

  FUNCTION f_get_overdue
  (
    p_credit_id      credits.credit_id%TYPE
   ,p_penalty_amount overdue.penalty_amount%TYPE DEFAULT 0
   ,p_check_date     DATE DEFAULT SYSDATE
  ) RETURN credits.amount%TYPE;

  PROCEDURE run_multithread (p_recalc_date DATE DEFAULT trunc(SYSDATE));

  PROCEDURE run_job
  (
    p_contracts t_credit_table
   ,p_debug     CHAR DEFAULT 'N'
   ,p_jobno     PLS_INTEGER
  );

END process_contracts_pkg;
/
