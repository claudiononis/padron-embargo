CLASS zcl_padron_processor DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_resumen,
             procesados    TYPE i,
             bloqueados    TYPE i,
             desbloqueados TYPE i,
             errores       TYPE i,
           END OF ty_resumen.

    METHODS procesar
      IMPORTING iv_run_id          TYPE sysuuid_x16
                iv_blocking_reason TYPE c
                iv_modo_test       TYPE abap_boolean DEFAULT abap_true
                iv_quitar_bloqueo  TYPE abap_boolean DEFAULT abap_false
      RETURNING VALUE(rs_resumen)  TYPE ty_resumen.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_estado,
             supplier        TYPE c LENGTH 10,
             company_code    TYPE c LENGTH 4,
             blocking_reason TYPE c LENGTH 1,
           END OF ty_estado.

    METHODS log
      IMPORTING iv_run_id    TYPE sysuuid_x16
                iv_line      TYPE i
                iv_cuit      TYPE c
                iv_supplier  TYPE c
                iv_company   TYPE c
                iv_resultado TYPE c
                iv_mensaje   TYPE string.
ENDCLASS.



CLASS ZCL_PADRON_PROCESSOR IMPLEMENTATION.


  METHOD procesar.

    SELECT * FROM zttxt
      WHERE run_id = @iv_run_id
      INTO TABLE @DATA(lt_stg).

    rs_resumen-procesados = lines( lt_stg ).
    IF lt_stg IS INITIAL.
      RETURN.
    ENDIF.

    " === leo el estado ACTUAL de bloqueo de los proveedores del staging (set-based) ===
    SELECT Supplier              AS supplier,
           CompanyCode           AS company_code,
           PaymentBlockingReason AS blocking_reason
      FROM i_suppliercompany
      FOR ALL ENTRIES IN @lt_stg
      WHERE Supplier    = @lt_stg-supplier
        AND CompanyCode = @lt_stg-company_code
      INTO TABLE @DATA(lt_estado).

    " indexo por proveedor+sociedad para consulta rapida
    DATA lt_estado_idx TYPE HASHED TABLE OF ty_estado
      WITH UNIQUE KEY supplier company_code.
    LOOP AT lt_estado INTO DATA(ls_e).
      INSERT VALUE #( supplier        = ls_e-supplier
                      company_code    = ls_e-company_code
                      blocking_reason = ls_e-blocking_reason ) INTO TABLE lt_estado_idx.
    ENDLOOP.

    DATA(lo_writer) = NEW zcl_padron_writer( ).
    DATA lv_desde_commit TYPE i VALUE 0.
    CONSTANTS c_chunk TYPE i VALUE 100.

    LOOP AT lt_stg INTO DATA(ls).

      " --- estado actual del proveedor ---
      READ TABLE lt_estado_idx INTO DATA(ls_est)
        WITH KEY supplier = ls-supplier company_code = ls-company_code.
      DATA(lv_existe)       = xsdbool( sy-subrc = 0 ).
      DATA(lv_ya_bloqueado) = xsdbool( lv_existe = abap_true AND ls_est-blocking_reason IS NOT INITIAL ).

      IF lv_existe = abap_false.
        " no existe en la sociedad (por robustez; el matcher ya deberia filtrarlo)
        rs_resumen-errores += 1.
        log( iv_run_id = iv_run_id iv_line = ls-line_number
             iv_cuit = ls-cuit iv_supplier = ls-supplier iv_company = ls-company_code
             iv_resultado = 'NO_ENCONTRADO'
             iv_mensaje = 'El proveedor no existe en la sociedad indicada.' ).

      ELSEIF iv_quitar_bloqueo = abap_false.
        " ================= ACCION: BLOQUEAR =================
        IF lv_ya_bloqueado = abap_true.
          rs_resumen-errores += 1.
          log( iv_run_id = iv_run_id iv_line = ls-line_number
               iv_cuit = ls-cuit iv_supplier = ls-supplier iv_company = ls-company_code
               iv_resultado = 'YA_BLOQUEADO'
               iv_mensaje = COND #( WHEN iv_modo_test = abap_true
                                    THEN 'Simulacion: el proveedor ya esta bloqueado (no se modificaria).'
                                    ELSE 'El proveedor ya se encuentra bloqueado.' ) ).
        ELSE.
          IF iv_modo_test = abap_true.
            rs_resumen-bloqueados += 1.
            log( iv_run_id = iv_run_id iv_line = ls-line_number
                 iv_cuit = ls-cuit iv_supplier = ls-supplier iv_company = ls-company_code
                 iv_resultado = 'TEST_OK' iv_mensaje = 'Simulacion: el pago se bloquearia.' ).
          ELSE.
            DATA(ls_rb) = lo_writer->bloquear_pago(
              iv_supplier        = ls-supplier
              iv_company_code    = ls-company_code
              iv_blocking_reason = iv_blocking_reason
              iv_quitar_bloqueo  = abap_false ).
            IF ls_rb-ok = abap_true.
              rs_resumen-bloqueados += 1.
              log( iv_run_id = iv_run_id iv_line = ls-line_number
                   iv_cuit = ls-cuit iv_supplier = ls-supplier iv_company = ls-company_code
                   iv_resultado = 'BLOQUEADO' iv_mensaje = ls_rb-message ).
            ELSE.
              rs_resumen-errores += 1.
              log( iv_run_id = iv_run_id iv_line = ls-line_number
                   iv_cuit = ls-cuit iv_supplier = ls-supplier iv_company = ls-company_code
                   iv_resultado = 'ERROR' iv_mensaje = ls_rb-message ).
            ENDIF.
          ENDIF.
        ENDIF.

      ELSE.
        " ================= ACCION: DESBLOQUEAR =================
        IF lv_ya_bloqueado = abap_false.
          rs_resumen-errores += 1.
          log( iv_run_id = iv_run_id iv_line = ls-line_number
               iv_cuit = ls-cuit iv_supplier = ls-supplier iv_company = ls-company_code
               iv_resultado = 'NO_BLOQUEADO'
               iv_mensaje = COND #( WHEN iv_modo_test = abap_true
                                    THEN 'Simulacion: el proveedor no esta bloqueado (nada para desbloquear).'
                                    ELSE 'El proveedor no se encuentra bloqueado.' ) ).
        ELSE.
          IF iv_modo_test = abap_true.
            rs_resumen-desbloqueados += 1.
            log( iv_run_id = iv_run_id iv_line = ls-line_number
                 iv_cuit = ls-cuit iv_supplier = ls-supplier iv_company = ls-company_code
                 iv_resultado = 'TEST_OK' iv_mensaje = 'Simulacion: el pago se desbloquearia.' ).
          ELSE.
            DATA(ls_rd) = lo_writer->bloquear_pago(
              iv_supplier        = ls-supplier
              iv_company_code    = ls-company_code
              iv_blocking_reason = iv_blocking_reason
              iv_quitar_bloqueo  = abap_true ).
            IF ls_rd-ok = abap_true.
              rs_resumen-desbloqueados += 1.
              log( iv_run_id = iv_run_id iv_line = ls-line_number
                   iv_cuit = ls-cuit iv_supplier = ls-supplier iv_company = ls-company_code
                   iv_resultado = 'DESBLOQUEADO' iv_mensaje = ls_rd-message ).
            ELSE.
              rs_resumen-errores += 1.
              log( iv_run_id = iv_run_id iv_line = ls-line_number
                   iv_cuit = ls-cuit iv_supplier = ls-supplier iv_company = ls-company_code
                   iv_resultado = 'ERROR' iv_mensaje = ls_rd-message ).
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      lv_desde_commit += 1.
      IF lv_desde_commit >= c_chunk.
        COMMIT WORK.
        lv_desde_commit = 0.
      ENDIF.

    ENDLOOP.

    IF lv_desde_commit > 0.
      COMMIT WORK.
    ENDIF.

  ENDMETHOD.


  METHOD log.
    GET TIME STAMP FIELD DATA(lv_ts).
    INSERT zttxt_log FROM @( VALUE #(
      run_id       = iv_run_id
      line_number  = iv_line
      cuit         = iv_cuit
      supplier     = iv_supplier
      company_code = iv_company
      resultado    = iv_resultado
      mensaje      = iv_mensaje
      created_at   = lv_ts ) ).
  ENDMETHOD.
ENDCLASS.
