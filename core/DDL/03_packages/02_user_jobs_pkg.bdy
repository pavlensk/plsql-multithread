CREATE OR REPLACE PACKAGE BODY user_jobs_pkg AS

  FUNCTION get_oratype_name(p_type_id INTEGER) RETURN VARCHAR2
    DETERMINISTIC IS
    TYPE tarr_oratype IS TABLE OF VARCHAR2(64) INDEX BY PLS_INTEGER;
    v_oratype tarr_oratype;
    v_name    VARCHAR2(64);
  BEGIN
    v_oratype(1) := 'VARCHAR2';
    v_oratype(2) := 'NUMBER';
    v_oratype(3) := 'BINARY_INTEGER';
    v_oratype(8) := 'LONG';
    v_oratype(11) := 'ROWID';
    v_oratype(12) := 'DATE';
    v_oratype(23) := 'RAW';
    v_oratype(24) := 'LONG RAW';
    v_oratype(58) := 'OPAQUE TYPE';
    v_oratype(96) := 'CHAR';
    v_oratype(100) := 'BINARY_FLOAT';
    v_oratype(101) := 'BINARY_DOUBLE';
    v_oratype(104) := 'UROWID';
    v_oratype(106) := 'MLSLABEL';
    v_oratype(112) := 'CLOB';
    v_oratype(113) := 'BLOB';
    v_oratype(114) := 'BFILE';
    v_oratype(121) := 'OBJECT';
    v_oratype(122) := 'TABLE';
    v_oratype(123) := 'VARRAY';
    v_oratype(178) := 'TIME';
    v_oratype(179) := 'TIME WITH TIME ZONE';
    v_oratype(180) := 'TIMESTAMP';
    v_oratype(181) := 'TIMESTAMP WITH TIME ZONE';
    v_oratype(182) := 'INTERVAL YEAR TO MONTH';
    v_oratype(183) := 'INTERVAL DAY TO SECOND';
    v_oratype(231) := 'TIMESTAMP WITH LOCAL TIME ZONE';
    v_oratype(250) := 'PL/SQL RECORD';
    v_oratype(251) := 'PL/SQL TABLE';
    v_oratype(252) := 'PL/SQL BOOLEAN';
  
    IF v_oratype.exists(p_type_id)
    THEN
      v_name := v_oratype(p_type_id);
    END IF;
  
    RETURN v_name;
  END get_oratype_name;

  FUNCTION describe_procedure(p_name VARCHAR2) RETURN t_describe IS
    v_describe t_describe;
  BEGIN
    v_describe.name := p_name;
    dbms_describe.describe_procedure(object_name   => v_describe.name
                                    ,reserved1     => NULL
                                    ,reserved2     => NULL
                                    ,overload      => v_describe.overload
                                    ,position      => v_describe.position
                                    ,LEVEL         => v_describe.level
                                    ,argument_name => v_describe.argument_name
                                    ,datatype      => v_describe.datatype
                                    ,default_value => v_describe.default_value
                                    ,in_out        => v_describe.in_out
                                    ,length        => v_describe.length
                                    ,PRECISION     => v_describe.precision
                                    ,scale         => v_describe.scale
                                    ,radix         => v_describe.radix
                                    ,spare         => v_describe.spare);
    RETURN v_describe;
  END describe_procedure;

  PROCEDURE create_program
  (
    p_program_name   VARCHAR2
   ,p_program_action VARCHAR2
  ) IS
  
    e_program_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_program_not_exist, -27476);
    e_not_all_arguments_defined EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_all_arguments_defined, -27456);
    v_object_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(v_object_not_exist, -06564);
    v_create              BOOLEAN := FALSE;
    v_describe            t_describe;
    e_number_of_arguments PLS_INTEGER := 0;
  BEGIN
    IF TRIM(p_program_name) IS NULL
       OR TRIM(p_program_action) IS NULL
    THEN
      raise_application_error(-20003
                             ,'Входные параметры должны быть заполнены.');
    END IF;
  
    BEGIN
      dbms_scheduler.enable(p_program_name);
    EXCEPTION
      WHEN e_program_not_exist THEN
        v_create := TRUE;
      WHEN e_not_all_arguments_defined THEN
        -- если неверные аргументы, пересоздаем
        dbms_scheduler.drop_program(p_program_name, TRUE);
        v_create := TRUE;
    END;
  
    IF v_create
    THEN
      -- если нет такой программы
      v_describe := describe_procedure(p_program_action); -- Если объекта нет, то v_object_not_exist
      -- Если есть аргументы у процедуры
      IF v_describe.overload.count > 0
      THEN
        -- Если количество агрументов 1 и имя аргумента null - это процедура без параметров
        IF v_describe.position.count > 0
           AND v_describe.argument_name(1) IS NOT NULL
        THEN
          e_number_of_arguments := v_describe.position(v_describe.position.last);
        END IF;
      END IF;
      -- Создание программы
      dbms_scheduler.create_program(program_name        => p_program_name
                                   ,program_type        => 'STORED_PROCEDURE'
                                   ,program_action      => p_program_action
                                   ,number_of_arguments => e_number_of_arguments
                                   , -- кол-во параметров
                                    enabled             => FALSE
                                   ,comments            => '');
      -- Набираем параметры
      IF v_describe.overload.count > 0
      THEN
        FOR i IN v_describe.overload.first .. v_describe.overload.last LOOP
          IF v_describe.argument_name(i) IS NOT NULL
          THEN
            dbms_scheduler.define_program_argument(program_name      => p_program_name
                                                  ,argument_position => v_describe.position(i)
                                                  ,argument_name     => v_describe.argument_name(i)
                                                  ,argument_type     => get_oratype_name(v_describe.datatype(i))
                                                  ,default_value     => '');
          END IF;
        END LOOP;
      END IF;
    
      -- Включаем программу
      dbms_scheduler.enable(p_program_name);
    END IF;
  
  EXCEPTION
    WHEN v_object_not_exist THEN
      dbms_output.put_line('Ошибка при создании программы');
      dbms_output.put_line(p_program_action || ' - не найдена');
      RAISE;
    WHEN OTHERS THEN
      dbms_output.put_line('Ошибка при создании программы');
      dbms_output.put_line(SQLERRM);
      RAISE;
  END create_program;

  PROCEDURE create_user_job
  (
    p_program_name   VARCHAR2
   ,p_program_action VARCHAR2
   ,p_arguments      IN OUT NOCOPY sys.jobarg_array
   ,p_job_prefix     VARCHAR2 DEFAULT 'JOB$_'
   ,p_debug_mode     BOOLEAN DEFAULT FALSE
   ,p_need_jobno     BOOLEAN DEFAULT FALSE
  ) IS
    v_name      VARCHAR2(256) := dbms_scheduler.generate_job_name(p_job_prefix);
    v_newjobarr sys.job_array;
  BEGIN
    create_program(p_program_name, p_program_action);

    IF p_need_jobno THEN
      p_arguments.extend;
      p_arguments(p_arguments.count) := sys.jobarg(p_arguments.count
                                                  ,anydata.ConvertNumber(Replace(v_name, p_job_prefix)));
    END IF;

    IF p_debug_mode
    THEN
      DECLARE
        l_anytype    anytype;
        l_typecode   PLS_INTEGER;
        l_char_value CHAR(1);
        l_num_value  Number;
        l_collection t_credit_table;
        l_status     VARCHAR2(64 CHAR);
      BEGIN
        FOR i IN 1 .. p_arguments.count LOOP
        
          -- Проверяем тип данных в ANYDATA
          l_typecode := p_arguments(i).arg_anydata_value.GetType(l_anytype);
        
          IF l_typecode = dbms_types.TYPECODE_NAMEDCOLLECTION THEN
            -- Извлекаем коллекцию
            IF p_arguments(i).arg_anydata_value.GetCollection(l_collection) = dbms_types.SUCCESS THEN
              l_status := 'record_count=: ' || l_collection.count();
            ELSE
              l_status := 'ошибка извлечения коллекции';
            END IF;
          ELSIF l_typecode = dbms_types.TYPECODE_CHAR Then
            IF p_arguments(i).arg_anydata_value.GetChar(l_char_value) = dbms_types.SUCCESS THEN
              l_status := l_char_value;
            END IF;
          ELSIF l_typecode = dbms_types.TYPECODE_NUMBER THEN 
            IF p_arguments(i).arg_anydata_value.GetNumber(l_num_value) = dbms_types.SUCCESS THEN
              l_status := l_num_value;
            END IF;
          ELSE
              l_status := 'неподдерживамый тип параметра';
          END IF;
          dbms_output.put_line('JOB ' || v_name || ', param ' || p_arguments(i).arg_position || ', ' || l_status);
        END LOOP;
      END;
    END IF;

    v_newjobarr := sys.job_array(sys.job(job_name     => v_name
                                        ,job_template => p_program_name
                                        ,job_style    => 'LIGHTWEIGHT'
                                        ,arguments    => p_arguments
                                        ,enabled      => TRUE));
  
    -- Произойдет полный rollback при ошибке
    dbms_scheduler.create_jobs(v_newjobarr, 'TRANSACTIONAL');
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('Ошибка при создании job');
      dbms_output.put_line(SQLERRM);
      dbms_output.put_line(dbms_utility.format_call_stack);
      dbms_output.put_line(dbms_utility.format_error_backtrace);
  END create_user_job;
END user_jobs_pkg;
/
