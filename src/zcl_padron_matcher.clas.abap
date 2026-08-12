CLASS zcl_padron_matcher DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_match,
             cuit         TYPE c LENGTH 11,
             supplier     TYPE c LENGTH 10,
             company_code TYPE c LENGTH 4,
             existe       TYPE abap_boolean,
             tiene_soc    TYPE abap_boolean,
           END OF ty_match,
           ty_matches TYPE STANDARD TABLE OF ty_match WITH EMPTY KEY.

TYPES: ty_cuit  TYPE i_supplier-taxnumber1.
    TYPES: ty_cuits TYPE STANDARD TABLE OF ty_cuit WITH EMPTY KEY.

    METHODS match
      IMPORTING it_cuits        TYPE ty_cuits
                iv_company_code TYPE c
      RETURNING VALUE(rt_matches) TYPE ty_matches.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_PADRON_MATCHER IMPLEMENTATION.


  METHOD match.

    IF it_cuits IS INITIAL.
      RETURN.
    ENDIF.

    SELECT
        sup~TaxNumber1   AS cuit,
        sup~Supplier     AS supplier,
        cmp~CompanyCode  AS company_code
      FROM i_supplier AS sup
      LEFT OUTER JOIN i_suppliercompany AS cmp
        ON  cmp~Supplier    = sup~Supplier
        AND cmp~CompanyCode = @iv_company_code
      FOR ALL ENTRIES IN @it_cuits
      WHERE sup~TaxNumber1 = @it_cuits-table_line
      INTO TABLE @DATA(lt_raw).

    LOOP AT lt_raw INTO DATA(ls_raw).
      APPEND VALUE #(
        cuit         = ls_raw-cuit
        supplier     = ls_raw-supplier
        company_code = ls_raw-company_code
        existe       = abap_true
        tiene_soc    = COND #( WHEN ls_raw-company_code IS NOT INITIAL
                               THEN abap_true ELSE abap_false )
      ) TO rt_matches.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
