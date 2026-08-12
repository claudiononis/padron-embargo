CLASS zcl_padron_ingesta DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_resumen,
             total_archivo TYPE i,   " líneas parseadas del TXT
             guardados     TYPE i,   " bloqueables: existen Y tienen sociedad
             sin_sociedad  TYPE i,   " existen pero sin segmento en la sociedad
             no_encontr    TYPE i,   " CUIT que no es proveedor
           END OF ty_resumen.

    METHODS ingestar
      IMPORTING iv_run_id         TYPE sysuuid_x16
                iv_contenido      TYPE string
                iv_company_code   TYPE c
      RETURNING VALUE(rs_resumen) TYPE ty_resumen.
ENDCLASS.



CLASS ZCL_PADRON_INGESTA IMPLEMENTATION.


  METHOD ingestar.

    " 1. PARSER: TXT -> líneas estructuradas
    DATA(lo_parser) = NEW zcl_padron_parser( ).
    DATA(lt_lineas) = lo_parser->parse( iv_contenido ).
    rs_resumen-total_archivo = lines( lt_lineas ).

    IF lt_lineas IS INITIAL.
      RETURN.
    ENDIF.

    " 2. junto los CUITs para el match set-based
    DATA lt_cuits TYPE zcl_padron_matcher=>ty_cuits.
    LOOP AT lt_lineas INTO DATA(ls_linea).
      APPEND ls_linea-cuit TO lt_cuits.
    ENDLOOP.

    " 3. MATCHER: cruzo contra I_Supplier (una sola pasada)
    DATA(lo_matcher) = NEW zcl_padron_matcher( ).
    DATA(lt_matches) = lo_matcher->match(
      it_cuits        = lt_cuits
      iv_company_code = iv_company_code ).

    " indexo los matches por CUIT
    DATA lt_match_idx TYPE HASHED TABLE OF zcl_padron_matcher=>ty_match
      WITH UNIQUE KEY cuit.
    LOOP AT lt_matches INTO DATA(ls_m).
      INSERT ls_m INTO TABLE lt_match_idx.
    ENDLOOP.

    " 4. armo el staging SOLO con los bloqueables (existen + tienen sociedad)
    DATA lt_staging TYPE STANDARD TABLE OF zttxt.

    LOOP AT lt_lineas INTO ls_linea.
      READ TABLE lt_match_idx INTO ls_m WITH KEY cuit = ls_linea-cuit.

      IF sy-subrc <> 0.
        rs_resumen-no_encontr += 1.        " no es proveedor
        CONTINUE.
      ENDIF.

      IF ls_m-tiene_soc = abap_false.
        rs_resumen-sin_sociedad += 1.      " existe pero sin segmento -> no bloqueable
        CONTINUE.
      ENDIF.

      " existe y tiene sociedad -> al staging, con supplier ya resuelto
      APPEND VALUE #(
        run_id        = iv_run_id
        line_number   = ls_linea-line_number
        cuit          = ls_linea-cuit
        supplier      = ls_m-supplier
        company_code  = iv_company_code
        fecha_embargo = ls_linea-fecha_embargo
        razon_social  = ls_linea-razon_social
        linea_cruda   = ls_linea-linea_cruda
      ) TO lt_staging.

      rs_resumen-guardados += 1.
    ENDLOOP.

    " 5. inserto todo el staging de una (set-based)
    IF lt_staging IS NOT INITIAL.
      INSERT zttxt FROM TABLE @lt_staging.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
