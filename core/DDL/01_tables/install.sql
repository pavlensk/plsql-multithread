CREATE TABLE credits (
    credit_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id      NUMBER NOT NULL,
    amount         NUMBER(15,2) NOT NULL,
    interest_rate  NUMBER(5,2) NOT NULL,
    start_date     DATE NOT NULL,
    end_date       DATE NOT NULL,
    due_day        NUMBER(2) NOT NULL,
    regular_sum    NUMBER(15,2) NOT NULL,
    status         VARCHAR2(20) CHECK (status IN ('active', 'closed', 'overdue'))
);

CREATE TABLE payments (
    payment_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    credit_id      NUMBER NOT NULL,
    payment_date   DATE NOT NULL,
    amount         NUMBER(15,2) NOT NULL,
    CONSTRAINT fk_payments_credit FOREIGN KEY (credit_id) REFERENCES credits(credit_id) ON DELETE CASCADE
);

CREATE TABLE overdue (
    overdue_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    credit_id      NUMBER NOT NULL,
    overdue_start  DATE NOT NULL,
    overdue_end    DATE,
    penalty_amount NUMBER(15,2) DEFAULT 0,
    comments       VARCHAR2(255 Char),
    CONSTRAINT fk_overdue_credit FOREIGN KEY (credit_id) REFERENCES credits(credit_id) ON DELETE CASCADE
);

CREATE TABLE RECALC_CONTRACT_LOG
(
  id    NUMBER,
  name  VARCHAR2(200 CHAR),
  value VARCHAR2(200 CHAR)
);