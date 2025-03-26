CREATE OR REPLACE PACKAGE const_pkg AS

  c_credit_active  CONSTANT credits.status%TYPE := 'active';
  c_credit_closed  CONSTANT credits.status%TYPE := 'closed';
  c_credit_overdue CONSTANT credits.status%TYPE := 'overdue';

  c_yes CONSTANT CHAR(1) := 'Y';
  c_no  CONSTANT CHAR(1) := 'N';

  c_input_rows  CONSTANT recalc_contract_log.name%TYPE := 'In rows';
  c_output_rows CONSTANT recalc_contract_log.name%TYPE := 'Aff rows';

END const_pkg;
/
