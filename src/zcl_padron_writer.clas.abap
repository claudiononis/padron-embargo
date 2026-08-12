CLASS zcl_padron_writer DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_result,
             supplier      TYPE c LENGTH 10,
             company_code  TYPE c LENGTH 4,
             ok            TYPE abap_boolean,
             status        TYPE i,
             message       TYPE string,   " mensaje amigable (se muestra en la tabla)
             message_tech  TYPE string,   " detalle tecnico (NO se muestra; solo debug/soporte)
           END OF ty_result.

    METHODS bloquear_pago
      IMPORTING iv_supplier        TYPE c
                iv_company_code    TYPE c
                iv_blocking_reason TYPE c
                iv_quitar_bloqueo  TYPE abap_boolean DEFAULT abap_false
      RETURNING VALUE(rs_result)   TYPE ty_result.

    METHODS listar_supplier_company
      RETURNING VALUE(rv_texto) TYPE string.

  PRIVATE SECTION.
    CONSTANTS:
      c_comm_scenario TYPE c LENGTH 30 VALUE 'ZCS_PADRON_BP_API',
      c_comm_system   TYPE c LENGTH 30 VALUE 'Z_PADRON_SELF_API',
      c_service_id    TYPE c LENGTH 30 VALUE 'ZOS_PADRON_BP_API_REST',
      c_base_path     TYPE string        VALUE '/sap/opu/odata/sap/API_BUSINESS_PARTNER'.

    METHODS get_http_client
      RETURNING VALUE(ro_client) TYPE REF TO if_web_http_client
      RAISING   cx_static_check.

    METHODS get_proxy
      RETURNING VALUE(ro_proxy) TYPE REF TO /iwbep/if_cp_client_proxy
      RAISING   cx_static_check.

    " arma el mensaje que ve el usuario
    METHODS build_user_message
      IMPORTING iv_ok         TYPE abap_boolean
                iv_quitar     TYPE abap_boolean
                iv_status     TYPE i
                iv_resp       TYPE string
      RETURNING VALUE(rv_msg) TYPE string.

    " intenta extraer el texto legible del JSON de error de SAP
    METHODS extract_sap_message
      IMPORTING iv_resp        TYPE string
      RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.



CLASS ZCL_PADRON_WRITER IMPLEMENTATION.


  METHOD extract_sap_message.
    " del JSON de error de SAP saco el primer "value":"<texto>" (el mensaje legible)
    FIND REGEX '"value"\s*:\s*"([^"]+)"' IN iv_resp SUBMATCHES rv_text.
    IF sy-subrc <> 0.
      CLEAR rv_text.
    ENDIF.
  ENDMETHOD.


  METHOD get_proxy.
    ro_proxy = /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
      is_proxy_model_key       = VALUE #(
        repository_id       = 'DEFAULT'
        proxy_model_id      = 'ZSCM_API_BUSINESS_PARTNER'
        proxy_model_version = '0001' )
      io_http_client           = get_http_client( )
      iv_relative_service_root = '/' ).
  ENDMETHOD.


  METHOD build_user_message.
    " CASO OK
    IF iv_ok = abap_true.
      rv_msg = COND #( WHEN iv_quitar = abap_true
                       THEN 'Pago desbloqueado correctamente'
                       ELSE 'Pago bloqueado correctamente' ).
      RETURN.
    ENDIF.

    " CASOS DE ERROR: traduzco los conocidos a algo entendible
    IF iv_resp CS 'ZAHLS'.
      rv_msg = 'La clave de bloqueo indicada no esta configurada en el sistema. Contactar al equipo funcional.'.

    ELSEIF iv_status = 404.
      rv_msg = 'El proveedor no existe en la sociedad indicada.'.

    ELSEIF iv_status = 401 OR iv_status = 403.
      rv_msg = 'Sin autorizacion para actualizar el proveedor.'.

    ELSE.
      " para errores no previstos, uso el texto legible que devuelve SAP (no el JSON crudo)
      DATA(lv_sap) = extract_sap_message( iv_resp ).
      rv_msg = COND #( WHEN lv_sap IS NOT INITIAL
                       THEN |No se pudo aplicar el cambio: { lv_sap }|
                       ELSE 'No se pudo aplicar el cambio en el proveedor.' ).
    ENDIF.
  ENDMETHOD.


  METHOD bloquear_pago.
    rs_result-supplier     = iv_supplier.
    rs_result-company_code = iv_company_code.

    TRY.
        DATA(lo_client) = get_http_client( ).

        " PATH COMPLETO (con el prefijo del servicio)
        DATA(lv_path) = |{ c_base_path }/A_SupplierCompany(Supplier='{ iv_supplier }',CompanyCode='{ iv_company_code }')|.

        " ---- 1) GET: traer CSRF token + ETag ----
        DATA(lo_req_get) = lo_client->get_http_request( ).
        lo_req_get->set_header_field( i_name = 'x-csrf-token' i_value = 'fetch' ).
        lo_req_get->set_header_field( i_name = 'Accept'       i_value = 'application/json' ).
        lo_req_get->set_uri_path( i_uri_path = lv_path ).

        DATA(lo_resp_get)   = lo_client->execute( if_web_http_client=>get ).
        DATA(lv_get_status) = lo_resp_get->get_status( )-code.
        DATA(lv_csrf)       = lo_resp_get->get_header_field( 'x-csrf-token' ).
        DATA(lv_etag)       = lo_resp_get->get_header_field( 'etag' ).

        " ---- 2) PATCH: bloquear o desbloquear segun el flag ----
        DATA lv_body TYPE string.
        IF iv_quitar_bloqueo = abap_true.
          lv_body = |\{"PaymentBlockingReason":""\}|.
        ELSE.
          lv_body = |\{"PaymentBlockingReason":"{ iv_blocking_reason }"\}|.
        ENDIF.

        DATA(lo_req_patch) = lo_client->get_http_request( ).
        lo_req_patch->set_header_field( i_name = 'x-csrf-token' i_value = lv_csrf ).
        lo_req_patch->set_header_field( i_name = 'If-Match'     i_value = lv_etag ).
        lo_req_patch->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
        lo_req_patch->set_uri_path( i_uri_path = lv_path ).
        lo_req_patch->set_text( i_text = lv_body ).

        DATA(lo_resp_patch) = lo_client->execute( if_web_http_client=>patch ).
        DATA(lv_status)     = lo_resp_patch->get_status( )-code.
        rs_result-status    = lv_status.

        IF lv_status BETWEEN 200 AND 299.
          rs_result-ok = abap_true.
        ELSE.
          rs_result-ok = abap_false.
        ENDIF.

        DATA(lv_resp_text) = lo_resp_patch->get_text( ).

        " mensaje amigable para la tabla
        rs_result-message = build_user_message(
          iv_ok     = rs_result-ok
          iv_quitar = iv_quitar_bloqueo
          iv_status = lv_status
          iv_resp   = lv_resp_text ).

        " detalle tecnico, guardado aparte (no se muestra al usuario)
        DATA(lv_accion) = COND string( WHEN iv_quitar_bloqueo = abap_true THEN 'DESBLOQ' ELSE 'BLOQ' ).
        rs_result-message_tech =
          |{ lv_accion } GET={ lv_get_status } TokenLen={ strlen( lv_csrf ) } ETag=[{ lv_etag }] >> PATCH={ lv_status } / { lv_resp_text }|.

      CATCH cx_root INTO DATA(lx).
        rs_result-ok           = abap_false.
        rs_result-message      = 'No se pudo conectar con el servicio para actualizar el proveedor.'.
        rs_result-message_tech = lx->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_http_client.
    DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
      comm_scenario  = CONV #( c_comm_scenario )
      comm_system_id = CONV #( c_comm_system )
      service_id     = CONV #( c_service_id ) ).

    ro_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).
  ENDMETHOD.


  METHOD listar_supplier_company.
    TRY.
        DATA(lo_proxy) = get_proxy( ).

        DATA(lo_request) = lo_proxy->create_resource_for_entity_set(
          'A_SUPPLIER_COMPANY' )->create_request_for_read( ).
        lo_request->set_top( 10 ).

        DATA lt_data TYPE STANDARD TABLE OF
          zscm_api_business_partner=>tys_a_supplier_company_type.
        lo_request->execute( )->get_business_data( IMPORTING et_business_data = lt_data ).

        LOOP AT lt_data INTO DATA(ls).
          rv_texto = |{ rv_texto }Supplier={ ls-supplier } CC={ ls-company_code } Bloqueo=[{ ls-payment_blocking_reason }] / |.
        ENDLOOP.
        IF rv_texto IS INITIAL.
          rv_texto = 'Respondio sin filas'.
        ENDIF.

      CATCH cx_root INTO DATA(lx).
        rv_texto = lx->get_text( ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
