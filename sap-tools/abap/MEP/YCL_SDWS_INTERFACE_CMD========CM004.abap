  METHOD fetch_data_cmd.
*    raising YCX_SDWS_INTERFACE.

    DATA ls_i_master_data TYPE cmds_ei_main.
    DATA ls_e_master_data TYPE cmds_ei_main.
    DATA ls_error TYPE cvis_message.
    DATA  ls_cust TYPE cmds_ei_extern.
    ls_cust-header-object_instance-kunnr = mv_ref_customer.
    ls_cust-header-object_task = 'M'.

    APPEND ls_cust TO ls_i_master_data-customers.

    cmd_ei_api_extract=>get_data(
      EXPORTING
        is_master_data = ls_i_master_data    " Ext. Schnittstelle:
      IMPORTING
        es_master_data = ms_ref_cmd    " Ext. Schnittstelle:
        es_error       =  ls_error ).   " Fehlerindikator und Systemnachrichten


    IF ls_error-is_error = abap_true.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>no_data_found
          mv_kunnr = mv_ref_customer
          mv_msgv1 = convert_syst_msgv( text-002 ).
    ENDIF.
  ENDMETHOD.
