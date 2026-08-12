CLASS zcl_padron_proc_test DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.



CLASS ZCL_PADRON_PROC_TEST IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    " tomo CUITs reales de 609 (los que tienen sociedad 3110)
    SELECT FROM i_supplier AS sup
      INNER JOIN i_suppliercompany AS cmp ON cmp~Supplier = sup~Supplier
      FIELDS sup~taxnumber1
      WHERE sup~taxnumber1 <> '' AND cmp~CompanyCode = '3110'
      ORDER BY sup~taxnumber1
      INTO TABLE @DATA(lt_cuit)
      UP TO 5 ROWS.

    IF lt_cuit IS INITIAL.
      out->write( 'No hay proveedores con CUIT en sociedad 3110' ).
      RETURN.
    ENDIF.

    " armo el TXT con el layout del padrón
    DATA lv_cuit11 TYPE c LENGTH 11.
    DATA lv_txt TYPE string.
    LOOP AT lt_cuit INTO DATA(ls).
      lv_cuit11 = ls-taxnumber1.
      lv_txt = lv_txt && |20250101{ lv_cuit11 WIDTH = 11 }0000000000000RAZON SOCIAL PRUEBA| && |{ cl_abap_char_utilities=>cr_lf }|.
    ENDLOOP.

    out->write( '=== COPIÁ ESTO Y PEGALO EN EL CAMPO CONTENIDO ===' ).
    out->write( lv_txt ).

  ENDMETHOD.
ENDCLASS.
