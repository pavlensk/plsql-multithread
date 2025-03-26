-- генерация кредитов
INSERT INTO credits
  (client_id, amount, interest_rate, start_date, end_date, due_day, regular_sum, status)
  SELECT client_id
        ,amount
        ,interest_rate
        ,start_date
        ,end_date
        ,TRUNC(dbms_random.value(1, 31))
        ,ROUND(amount * ( (interest_rate / 12 / 100) * POWER(1 + (interest_rate / 12 / 100), MONTHS_BETWEEN(end_date, start_date)) ) /
       (POWER(1 + (interest_rate / 12 / 100), MONTHS_BETWEEN(end_date, start_date)) - 1), 2) AS monthly_payment
        ,CASE
           WHEN end_date < SYSDATE THEN
            'closed'
           WHEN flag != 0 THEN
            'active'
           ELSE
            'overdue'
         END
    FROM (SELECT Rownum AS client_id                        -- случайный клиент (до 50 клиентов)
               , round(dbms_random.value(50000, 500000), 2) AS amount   -- сумма кредита от 50k до 500k
               , round(dbms_random.value(16, 24), 2) AS interest_rate   -- процентная ставка от 5% до 15%
               , trunc(add_months(SYSDATE, -LEVEL), 'DD') AS start_date -- дата начала кредита (в прошлом)
               , trunc(add_months(add_months(SYSDATE, -LEVEL)
                                 ,trunc(dbms_random.value(60, 84)))
                      ,'DD') AS end_date                                -- дата окончания (5-7 лет от старта)
               , MOD(LEVEL, 3) AS flag 
            FROM dual
          CONNECT BY LEVEL <= 100);

-- Генерация 40-60 платежей для каждого кредита
INSERT INTO payments
  (credit_id, payment_date, amount)
  SELECT credit_id, pay_date, amount
    FROM (SELECT c.credit_id
                ,add_months(trunc(c.start_date, 'MM') + c.due_day - 1
                           ,temp.lvl) AS pay_date
                ,c.regular_sum AS amount
                ,c.status
            FROM credits c
           CROSS JOIN (SELECT LEVEL lvl FROM dual CONNECT BY LEVEL <= 60) temp
           WHERE temp.lvl <= trunc(dbms_random.value(40, 60)))
   WHERE ( status = 'active'  AND pay_date <= SYSDATE)
      Or ( status = 'overdue' AND pay_date <= Sysdate - 30);