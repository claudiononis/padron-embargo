CLASS zcl_padron_job DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES if_bgmc_operation.
    INTERFACES if_bgmc_op_single_tx_uncontr.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    METHODS procesar_pendientes RETURNING VALUE(rv_log) TYPE string.
ENDCLASS.



CLASS ZCL_PADRON_JOB IMPLEMENTATION.


  METHOD if_bgmc_op_single_tx_uncontr~execute.
    procesar_pendientes( ).
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    out->write( procesar_pendientes( ) ).
  ENDMETHOD.


  METHOD procesar_pendientes.

    SELECT run_id, company_code, modo_test, blocking_reason, quitar_bloqueo, contenido, file_content
      FROM zttxt_run
      WHERE estado = 'PENDIENTE'
      INTO TABLE @DATA(lt_run).

    IF lt_run IS INITIAL.
      rv_log = 'No hay corridas PENDIENTES'.
      RETURN.
    ENDIF.

    DATA(lo_ing)  = NEW zcl_padron_ingesta( ).
    DATA(lo_proc) = NEW zcl_padron_processor( ).

    LOOP AT lt_run INTO DATA(ls_run).

      UPDATE zttxt_run SET estado = 'PROCESANDO' WHERE run_id = @ls_run-run_id.
      COMMIT WORK.

      " origen del texto: archivo subido (stream) o texto pegado
      DATA lv_texto TYPE string.
      IF ls_run-file_content IS NOT INITIAL.
        TRY.
            DATA(lo_conv) = cl_abap_conv_codepage=>create_in( ).
            lv_texto = lo_conv->convert( ls_run-file_content ).
          CATCH cx_root.
            lv_texto = ls_run-contenido.
        ENDTRY.
      ELSE.
        lv_texto = ls_run-contenido.
      ENDIF.

      DATA(ls_ing) = lo_ing->ingestar(
        iv_run_id       = ls_run-run_id
        iv_contenido    = lv_texto
        iv_company_code = ls_run-company_code ).

      DATA(ls_res) = lo_proc->procesar(
        iv_run_id          = ls_run-run_id
        iv_blocking_reason = ls_run-blocking_reason
        iv_modo_test       = ls_run-modo_test
        iv_quitar_bloqueo  = ls_run-quitar_bloqueo ).

      GET TIME STAMP FIELD DATA(lv_ts).
      UPDATE zttxt_run SET
          estado              = 'TERMINADO',
          total_registros     = @( ls_ing-total_archivo ),
          total_match         = @( ls_ing-guardados ),
          total_ignorados     = @( ls_ing-sin_sociedad ),
          total_bloqueados    = @( ls_res-bloqueados ),
          total_desbloqueados = @( ls_res-desbloqueados ),
          total_errores       = @( ls_res-errores ),
          last_changed_at     = @lv_ts
        WHERE run_id = @ls_run-run_id.
      COMMIT WORK.

      rv_log = |{ rv_log }Run: total={ ls_ing-total_archivo } match={ ls_ing-guardados } bloq={ ls_res-bloqueados } desbloq={ ls_res-desbloqueados } / |.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
