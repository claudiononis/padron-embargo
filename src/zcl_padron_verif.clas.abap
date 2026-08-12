CLASS zcl_padron_verif DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.



CLASS ZCL_PADRON_VERIF IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    " proveedores a verificar (los que bloqueó la corrida real)
    DATA(lt_suppliers) = VALUE string_table( ( `400000` ) ( `30000015` ) ).

    TRY.
        " misma conexión que usa el writer (comm arrangement de Fer)
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
          comm_scenario  = CONV #( 'ZCS_PADRON_BP_API' )
          comm_system_id = CONV #( 'Z_PADRON_SELF_API' )
          service_id     = CONV #( 'ZOS_PADRON_BP_API_REST' ) ).

        DATA(lo_client) = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).

        DATA(lo_proxy) = /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
          is_proxy_model_key       = VALUE #(
            repository_id       = 'DEFAULT'
            proxy_model_id      = 'ZSCM_API_BUSINESS_PARTNER'
            proxy_model_version = '0001' )
          io_http_client           = lo_client
          iv_relative_service_root = '/' ).

        " leo A_SupplierCompany completo (top 50) y filtro acá los que me interesan
        DATA(lo_request) = lo_proxy->create_resource_for_entity_set(
          'A_SUPPLIER_COMPANY' )->create_request_for_read( ).
        lo_request->set_top( 50 ).

        DATA lt_data TYPE STANDARD TABLE OF
          zscm_api_business_partner=>tys_a_supplier_company_type.
        lo_request->execute( )->get_business_data( IMPORTING et_business_data = lt_data ).

        out->write( '=== ESTADO DE BLOQUEO (leído por la API) ===' ).
        LOOP AT lt_data INTO DATA(ls).
          " muestro solo los suppliers que quiero verificar
          DATA(lv_sup) = |{ ls-supplier ALPHA = OUT }|.
          CONDENSE lv_sup.
          IF line_exists( lt_suppliers[ table_line = lv_sup ] ).
            DATA(lv_estado) = COND string(
              WHEN ls-payment_blocking_reason IS NOT INITIAL
              THEN |>>> BLOQUEADO con clave [{ ls-payment_blocking_reason }] <<<|
              ELSE |sin bloqueo| ).
            out->write( |Supplier { ls-supplier } / Sociedad { ls-company_code }: { lv_estado }| ).
          ENDIF.
        ENDLOOP.

      CATCH cx_root INTO DATA(lx).
        out->write( |ERROR: { lx->get_text( ) }| ).
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
