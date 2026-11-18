  METHOD write_log.
*        IMPORTING
*            is_import_avail TYPE ysdws_availability_i_s OPTIONAL
*            is_export_avail TYPE ysdws_availability_e_s OPTIONAL
*        changing
*            cs_log_time  type ysdws_log_time
*            ct_log_value type ysdws_log_value_tt.

    DATA ls_log_value TYPE ysdws_log_value.
    DATA lo_field_catalog  TYPE REF TO cl_abap_structdescr.

    " ===========================================================
    " ==> Allgemein GUID - Verknüpfung zwischen Log-Tabellen <===
    " ==           YSDWS_LOG_TIME + YSDWS_LOG_VALUE           ===
    " ===========================================================
*    CALL FUNCTION 'GUID_CREATE'
*      IMPORTING
*        ev_guid_16 = cs_log_time-guid.    " GUID in Länge 16 (RAW  Format)
    TRY.
        cs_log_time-guid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        cs_log_time-guid = '0'.
    ENDTRY.
    " ======================================
    " ==> Import-Struktur Verfügbarkeit <===
    " ======================================
    IF is_import_avail IS SUPPLIED.

      get_log_values_from_structure(
        EXPORTING
          is_structure      = is_import_avail
          is_log_time       = cs_log_time
          iv_interface_type = mc_intf_type_in
          iv_tabix          = mc_tabix_1
        CHANGING
          ct_log_value      = ct_log_value ).

      LOOP AT is_import_avail-it_mat ASSIGNING FIELD-SYMBOL(<ls_mat>).

        DATA(lv_tabix) = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure      = <ls_mat>
            is_log_time       = cs_log_time
            iv_interface_type = mc_intf_type_in
            iv_tabix          = lv_tabix
          CHANGING
            ct_log_value      = ct_log_value ).
      ENDLOOP.
    ENDIF.
    " ======================================
    " ==> Export-Struktur Verfügbarkeit <===
    " ======================================
    IF is_export_avail IS SUPPLIED.

      LOOP AT is_export_avail-et_kond ASSIGNING FIELD-SYMBOL(<ls_kond>).

        lv_tabix = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure    = <ls_kond>
            is_log_time     = cs_log_time
          iv_interface_type = mc_intf_type_out
            iv_tabix        = lv_tabix
          CHANGING
            ct_log_value    = ct_log_value ).

      ENDLOOP.

      LOOP AT is_export_avail-et_returns ASSIGNING FIELD-SYMBOL(<ls_return>).

        lv_tabix = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure    = <ls_return>
            is_log_time     = cs_log_time
          iv_interface_type = mc_intf_type_out
            iv_tabix        = lv_tabix
          CHANGING
            ct_log_value    = ct_log_value ).

      ENDLOOP.
    ENDIF.
    " =====================================
    " ==> Import-Struktur Preisanfrage <===
    " =====================================
    IF is_import_pricing IS SUPPLIED.

      get_log_values_from_structure(
        EXPORTING
          is_structure      = is_import_pricing
          is_log_time       = cs_log_time
          iv_interface_type = mc_intf_type_in
          iv_tabix          = mc_tabix_1
        CHANGING
          ct_log_value      = ct_log_value ).

      LOOP AT is_import_pricing-it_mat ASSIGNING FIELD-SYMBOL(<ls_pricing_mat>).

        lv_tabix = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure      = <ls_pricing_mat>
            is_log_time       = cs_log_time
            iv_interface_type = mc_intf_type_in
            iv_tabix          = lv_tabix
          CHANGING
            ct_log_value      = ct_log_value ).
      ENDLOOP.
    ENDIF.
    " =====================================
    " ==> Export-Struktur Preisanfrage <===
    " =====================================
    IF is_export_pricing IS SUPPLIED.

      LOOP AT is_export_pricing-et_kond ASSIGNING FIELD-SYMBOL(<ls_pricing_kond>).

        lv_tabix = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure    = <ls_pricing_kond>
            is_log_time     = cs_log_time
          iv_interface_type = mc_intf_type_out
            iv_tabix        = lv_tabix
          CHANGING
            ct_log_value    = ct_log_value ).

      ENDLOOP.

      LOOP AT is_export_pricing-et_returns ASSIGNING FIELD-SYMBOL(<ls_pricing_return>).

        lv_tabix = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure    = <ls_pricing_return>
            is_log_time     = cs_log_time
          iv_interface_type = mc_intf_type_out
            iv_tabix        = lv_tabix
          CHANGING
            ct_log_value    = ct_log_value ).

      ENDLOOP.
    ENDIF.


*      !IS_IMPORT_SALESORDER type YSDWS_SALESORDER_I_S optional
*      !IS_EXPORT_SALESORDER type YSDWS_SALESORDER_E_S optional

    " ===========================================
    " ==> Import-Struktur Auftragssimulation <===
    " ===========================================
    IF is_import_salesorder IS SUPPLIED.

      get_log_values_from_structure(
        EXPORTING
          is_structure      = is_import_salesorder
          is_log_time       = cs_log_time
          iv_interface_type = mc_intf_type_in
          iv_tabix          = mc_tabix_1
        CHANGING
          ct_log_value      = ct_log_value ).

      " header fields
      LOOP AT is_import_salesorder-i_header ASSIGNING FIELD-SYMBOL(<ls_so_header>).

        lv_tabix = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure      = <ls_so_header>
            is_log_time       = cs_log_time
            iv_interface_type = mc_intf_type_in
            iv_tabix          = lv_tabix
          CHANGING
            ct_log_value      = ct_log_value ).

      ENDLOOP.

      " item fields
      LOOP AT is_import_salesorder-i_item ASSIGNING FIELD-SYMBOL(<ls_so_item>).

        lv_tabix = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure      = <ls_so_item>
            is_log_time       = cs_log_time
            iv_interface_type = mc_intf_type_in
            iv_tabix          = lv_tabix
          CHANGING
            ct_log_value      = ct_log_value ).

      ENDLOOP.

    ENDIF.
    " ===========================================
    " ==> Export-Struktur Auftragssimulation <===
    " ===========================================
    IF is_export_salesorder IS SUPPLIED.


      get_log_values_from_structure(
        EXPORTING
          is_structure      = is_export_salesorder
          is_log_time       = cs_log_time
          iv_interface_type = mc_intf_type_out
          iv_tabix          = mc_tabix_1
        CHANGING
          ct_log_value      = ct_log_value ).

      LOOP AT is_export_salesorder-et_header ASSIGNING FIELD-SYMBOL(<ls_so_exp_header>).

        lv_tabix = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure    = <ls_so_exp_header>
            is_log_time     = cs_log_time
          iv_interface_type = mc_intf_type_out
            iv_tabix        = lv_tabix
          CHANGING
            ct_log_value    = ct_log_value ).

      ENDLOOP.

      LOOP AT is_export_salesorder-et_item ASSIGNING FIELD-SYMBOL(<ls_so_exp_item>).

        lv_tabix = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure    = <ls_so_exp_item>
            is_log_time     = cs_log_time
          iv_interface_type = mc_intf_type_out
            iv_tabix        = lv_tabix
          CHANGING
            ct_log_value    = ct_log_value ).

      ENDLOOP.

      LOOP AT is_export_salesorder-et_returns ASSIGNING FIELD-SYMBOL(<ls_so_returns>).

        lv_tabix = sy-tabix.

        get_log_values_from_structure(
          EXPORTING
            is_structure    = <ls_so_returns>
            is_log_time     = cs_log_time
          iv_interface_type = mc_intf_type_out
            iv_tabix        = lv_tabix
          CHANGING
            ct_log_value    = ct_log_value ).

      ENDLOOP.

    ENDIF.


  ENDMETHOD.
