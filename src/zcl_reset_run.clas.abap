CLASS zcl_reset_run DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.



CLASS ZCL_RESET_RUN IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    UPDATE zttxt_run
      SET estado = 'PENDIENTE',
          total_registros = 0,
          total_match = 0,
          total_bloqueados = 0,
          total_errores = 0,
          total_ignorados = 0
      WHERE run_id = @( CONV sysuuid_x16( 'FA163E3665841FD19FA8D26F7B1D09E1' ) ).

    COMMIT WORK.

    out->write( |Corridas reseteadas: { sy-dbcnt }| ).

    " limpio el log viejo de esa corrida para una prueba limpia
    DELETE FROM zttxt_log
      WHERE run_id = @( CONV sysuuid_x16( 'FA163E3665841FD19FA8D26F7B1D09E1' ) ).
    COMMIT WORK.

    " limpio también el staging de esa corrida
    DELETE FROM zttxt
      WHERE run_id = @( CONV sysuuid_x16( 'FA163E3665841FD19FA8D26F7B1D09E1' ) ).
    COMMIT WORK.

    out->write( 'Log y staging de la corrida limpiados.' ).

  ENDMETHOD.
ENDCLASS.
