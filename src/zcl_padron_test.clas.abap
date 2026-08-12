CLASS zcl_padron_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_PADRON_TEST IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

" ¿Hay proveedores en este sistema, con o sin CUIT?
    SELECT COUNT(*) FROM i_supplier INTO @DATA(lv_total).
    out->write( |Total de proveedores en I_Supplier: { lv_total }| ).

    " ¿Y business partners en general?
    SELECT COUNT(*) FROM i_businesspartner INTO @DATA(lv_bp).
    out->write( |Total de business partners en I_BusinessPartner: { lv_bp }| ).

  ENDMETHOD.
ENDCLASS.
