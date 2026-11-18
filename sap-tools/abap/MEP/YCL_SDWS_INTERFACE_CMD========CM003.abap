  METHOD create_new_customer.
*    raising YCX_SDWS_INTERFACE.

    DATA ls_error TYPE cvis_message.
    DATA ls_master_data_correct TYPE cmds_ei_main.
    DATA ls_message_correct TYPE cvis_message.
    DATA ls_master_data_defective   TYPE cmds_ei_main.
    DATA ls_message_defective   TYPE cvis_message.


    CALL METHOD cmd_ei_api=>initialize.

    CALL METHOD cmd_ei_api=>maintain_bapi(
      EXPORTING
*       iv_test_run              = iv_test_run
        iv_collect_messages      = 'X'
        is_master_data           = ms_new_cmd
      IMPORTING
        es_master_data_correct   = ls_master_data_correct
        es_message_correct       = ls_message_correct
        es_master_data_defective = ls_master_data_defective
        es_message_defective     = ls_message_defective ).

    IF NOT ls_message_correct-is_error IS INITIAL.

      LOOP AT ls_message_correct-messages ASSIGNING FIELD-SYMBOL(<mess>).
        set_msg_text( <mess> ).
      ENDLOOP.

      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>no_data_found
          mv_kunnr = mv_ref_customer
          mv_msgv1 = text-005.

    ENDIF.

    rv_new_customer = ls_master_data_correct-customers[ 1 ]-header-object_instance-kunnr.
    creditlimit_change( ls_master_data_correct-customers[ 1 ]-header-object_instance-kunnr ).

    objcl_create( ls_master_data_correct-customers[ 1 ]-header-object_instance-kunnr ).




  ENDMETHOD.
