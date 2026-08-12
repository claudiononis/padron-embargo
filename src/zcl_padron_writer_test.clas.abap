CLASS zcl_padron_writer_test DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.



CLASS ZCL_PADRON_WRITER_TEST IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA(lo_writer) = NEW zcl_padron_writer( ).

    out->write( |ANTES:| ).
    out->write( lo_writer->listar_supplier_company( ) ).

    DATA(ls_res) = lo_writer->bloquear_pago(
      iv_supplier        = '30000000'
      iv_company_code    = '3110'
      iv_blocking_reason = 'A' ).
    out->write( |---| ).
    out->write( |OK: { ls_res-ok } / Status: { ls_res-status }| ).
    out->write( |Msg: { ls_res-message }| ).

    out->write( |---| ).
    out->write( |DESPUES:| ).
    out->write( lo_writer->listar_supplier_company( ) ).

  ENDMETHOD.
ENDCLASS.
