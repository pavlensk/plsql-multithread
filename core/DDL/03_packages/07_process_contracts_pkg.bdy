CREATE OR REPLACE PACKAGE BODY process_contracts_pkg AS

  FUNCTION f_get_overdue
  (
    p_credit_id      credits.credit_id%TYPE
   ,p_penalty_amount overdue.penalty_amount%TYPE DEFAULT 0
   ,p_check_date     DATE DEFAULT SYSDATE
  ) RETURN credits.amount%TYPE IS
    l_total_payments    credits.amount%TYPE;
    l_expected_payments credits.amount%TYPE;
  BEGIN
    -- всего платежей
    SELECT SUM(p.amount)
      INTO l_total_payments
      FROM payments p
     WHERE p.credit_id = p_credit_id;
    -- ожидалось платежей
    SELECT SUM(floor(months_between(least(p_check_date, c.end_date)
                                   ,trunc(c.start_date, 'MM') +
                                    c.due_day - 1))) * c.regular_sum
      INTO l_expected_payments
      FROM credits c
     WHERE c.credit_id = p_credit_id
     GROUP BY c.regular_sum;
    -- NoFormat Start
    RETURN
        CASE
          WHEN (l_expected_payments + p_penalty_amount) <= l_total_payments
            THEN 0
          ELSE
            l_total_payments - (l_expected_payments + p_penalty_amount)
        END;
    -- NoFormat End
  END f_get_overdue;

  PROCEDURE run_job
  (
    p_contracts t_credit_table
   ,p_debug     CHAR DEFAULT 'N'
   ,p_jobno     PLS_INTEGER
  ) IS
    v_rowcount PLS_INTEGER;
  BEGIN
  
    MERGE INTO overdue o
    USING (SELECT s.p_credit_id, s.p_debt * 1.005 AS debt
             FROM TABLE(p_contracts) s
            WHERE s.p_credit_state = const_pkg.c_credit_overdue
              AND s.p_debt < 0) cred
    ON (o.credit_id = cred.p_credit_id AND o.overdue_end IS NULL)
    WHEN MATCHED THEN
      UPDATE SET o.penalty_amount = cred.debt
    WHEN NOT MATCHED THEN
      INSERT
        (credit_id, overdue_start, penalty_amount)
      VALUES
        (cred.p_credit_id, trunc(SYSDATE), cred.debt);
  
    v_rowcount := SQL%ROWCOUNT;
  
    IF p_debug = const_pkg.c_yes
    THEN
      INSERT INTO recalc_contract_log
        SELECT p_jobno, const_pkg.c_input_rows, COUNT(*)
          FROM TABLE(p_contracts) s
        UNION ALL
        SELECT p_jobno, const_pkg.c_output_rows, v_rowcount
          FROM dual;
    END IF;
  END run_job;

  -- ежедневный джоб расчета задолженности по кредитам
  PROCEDURE run_multithread(p_recalc_date DATE DEFAULT trunc(SYSDATE)) IS

    --=================
    -- блок констант
    --=================
    с_batch_size  CONSTANT PLS_INTEGER := 25; -- Размер пакета для обработки в одном джобе
    c_job_name    CONSTANT VARCHAR2(50) := 'JOB_PROC_CRED$'; -- префикс имени джоба
    c_max_jobs    CONSTANT PLS_INTEGER := 25; -- Максимальное число параллельных джобов
    -- статусы, по которым проводим расчеты
    c_statuses CONSTANT sys.odcivarchar2list := sys.odcivarchar2list(const_pkg.c_credit_active
                                                                    ,const_pkg.c_credit_overdue);
  
    CURSOR cur_credits_with_debt(p_statuses sys.odcivarchar2list) IS
      SELECT t_credit_data(p_credit_id    => c.credit_id
                          ,p_debt         => f_get_overdue(p_credit_id      => c.credit_id
                                                          ,p_penalty_amount => nvl(o.penalty_amount, 0)
                                                          ,p_check_date     => p_recalc_date)
                          ,p_credit_state => c.status)
        FROM credits c
        LEFT JOIN overdue o
          ON o.credit_id = c.credit_id
         AND o.overdue_end IS NULL
       WHERE c.status IN (SELECT column_value FROM TABLE(p_statuses));
  
    v_import_data t_credit_table;
    v_arguments   sys.jobarg_array;
    v_active_jobs PLS_INTEGER;

  BEGIN

    OPEN cur_credits_with_debt(c_statuses);

    LOOP
      -- Читаем очередной батч данных
      FETCH cur_credits_with_debt
       BULK COLLECT
       INTO v_import_data LIMIT с_batch_size;
       EXIT WHEN v_import_data.count = 0;

      -- Ждем, пока число активных джобов не снизится
      LOOP
        -- Проверяем количество активных джобов
        SELECT COUNT(*)
          INTO v_active_jobs
          FROM user_scheduler_jobs
         WHERE job_name LIKE c_job_name || '_%'
           AND state IN ('RUNNING', 'SCHEDULED');

        -- Если запущено меньше, чем MAX_JOBS_RUNNING, выходим из цикла
        EXIT WHEN v_active_jobs < c_max_jobs;

        -- Ждём 5 секунд, чтобы не перегружать БД
        dbms_session.sleep(5);
      END LOOP;

      v_arguments := sys.jobarg_array(sys.jobarg(1
                                                ,anydata.ConvertCollection(v_import_data))
                                     ,sys.jobarg(2
                                                ,anydata.ConvertChar(const_pkg.c_yes)));
      -- Создадим и запустим джоб
      user_jobs_pkg.create_user_job(p_program_name   => 'p_process_contracts'
                                   ,p_program_action => $$plsql_Unit || '.run_job'
                                   ,p_arguments      => v_arguments
                                   ,p_job_prefix     => c_job_name
                                   ,p_debug_mode     => TRUE
                                   ,p_need_jobno     => TRUE);

    END LOOP;
  
    -- Закрываем курсор
    CLOSE cur_credits_with_debt;
  END run_multithread;

END process_contracts_pkg;
/
