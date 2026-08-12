CLASS lhc_run DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Run
      RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Run
      RESULT result.

    METHODS setEstadoInicial FOR DETERMINE ON SAVE
      IMPORTING keys FOR Run~setEstadoInicial.

    METHODS procesar FOR MODIFY
      IMPORTING keys FOR ACTION Run~procesar.

    METHODS refrescar FOR MODIFY
      IMPORTING keys FOR ACTION Run~refrescar.
ENDCLASS.

CLASS lhc_run IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD setEstadoInicial.
    " al guardar una corrida nueva, la dejo en PENDIENTE
    MODIFY ENTITIES OF zi_padron_run IN LOCAL MODE
      ENTITY Run
      UPDATE FIELDS ( Estado )
      WITH VALUE #( FOR key IN keys
                    ( %tky   = key-%tky
                      Estado = 'PENDIENTE' ) )
      REPORTED DATA(lt_rep).
  ENDMETHOD.

  METHOD procesar.
  ENDMETHOD.

  METHOD refrescar.
    " Accion vacia a proposito: no modifica nada. Solo sirve como disparador
    " del side effect, que relee la cabecera y la tabla del log desde la base.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zi_padron_run DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zi_padron_run IMPLEMENTATION.

  METHOD save_modified.
    " 'create' trae las instancias creadas en esta transacción.
    " Si hubo al menos una, encolo el bgPF (variante controlada).
    IF create-run IS NOT INITIAL.
      TRY.
          DATA(lo_bgpf) = cl_bgmc_process_factory=>get_default( )->create( ).
          lo_bgpf->set_operation_tx_uncontrolled( NEW zcl_padron_job( ) ).
          lo_bgpf->save_for_execution( ).
        CATCH cx_bgmc INTO DATA(lx).
      ENDTRY.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
