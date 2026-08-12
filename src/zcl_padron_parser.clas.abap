CLASS zcl_padron_parser DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_linea,
             line_number   TYPE i,
             fecha_embargo TYPE c LENGTH 8,
             cuit          TYPE c LENGTH 11,
             razon_social  TYPE c LENGTH 121,
             linea_cruda   TYPE c LENGTH 153,
           END OF ty_linea,
           ty_lineas TYPE STANDARD TABLE OF ty_linea WITH EMPTY KEY.

    METHODS parse
      IMPORTING iv_contenido   TYPE string
      RETURNING VALUE(rt_lineas) TYPE ty_lineas.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_PADRON_PARSER IMPLEMENTATION.


  METHOD parse.

DATA lt_raw TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    " normalizo fines de línea: CRLF y CR -> LF, después corto por LF
    DATA(lv_norm) = iv_contenido.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_norm WITH cl_abap_char_utilities=>newline.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf(1) IN lv_norm WITH cl_abap_char_utilities=>newline.
    SPLIT lv_norm AT cl_abap_char_utilities=>newline INTO TABLE lt_raw.

    DATA lv_index TYPE i VALUE 0.

    LOOP AT lt_raw INTO DATA(lv_raw).

      IF strlen( lv_raw ) < 19.
        CONTINUE.
      ENDIF.

      lv_index = lv_index + 1.

      APPEND VALUE #(
        line_number   = lv_index
        fecha_embargo = lv_raw+0(8)
        cuit          = lv_raw+8(11)
        razon_social  = COND #( WHEN strlen( lv_raw ) >= 32
                                THEN lv_raw+32(*)
                                ELSE space )
        linea_cruda   = lv_raw
      ) TO rt_lineas.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
