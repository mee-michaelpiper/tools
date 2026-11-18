  METHOD create_salesorder.

    DATA lo_error TYPE REF TO ycx_sdws_interface.
    DATA ls_import TYPE ysdws_salesorder_i_s.
    DATA ls_return TYPE ysdws_return_e_s.
    DATA ls_bapiret TYPE  bapiret2.
    DATA lv_salesdocument TYPE vbeln.

    ls_import = is_import.
    map_import( ls_import ).
    plausi_checks( ).

    CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
      EXPORTING
*       SALESDOCUMENTIN      =
        order_header_in      = ms_order_header_in
*       ORDER_HEADER_INX     =
*       SENDER               =
*       BINARY_RELATIONSHIPTYPE       =
*       INT_NUMBER_ASSIGNMENT         =
        behave_when_error    = ls_import-i_behave_when_error
        logic_switch         = ms_logic_switch
        testrun              = set_run_mode( ls_import-i_commit )
*       CONVERT              = ' '
      IMPORTING
        salesdocument        = lv_salesdocument
      TABLES
        return               = mt_returns
        order_items_in       = mt_order_items_in
        order_items_inx      = mt_order_items_inx
        order_partners       = mt_order_partners
        order_schedules_in   = mt_order_schedules_in
        order_schedules_inx  = mt_order_schedules_inx
        order_conditions_in  = mt_order_conditions_in "zur Pflege der Konditionen im Auftrag
        order_conditions_inx = mt_order_conditions_inx "zur Pflege der Konditionen im Auftrag
        order_cfgs_ref       = ms_cfgs-t_ref[]
        order_cfgs_inst      = ms_cfgs-t_inst[]
        order_cfgs_part_of   = ms_cfgs-t_part_of[]
        order_cfgs_value     = ms_cfgs-t_value[]
        order_cfgs_blob      = ms_cfgs-t_blob[]
        order_cfgs_vk        = ms_cfgs-t_vk[]
        order_cfgs_refinst   = ms_cfgs-t_refinst[]
*       ORDER_CCARD          =
        order_text           = mt_order_text
*       ORDER_KEYS           =
        extensionin          = mt_extensionin  " ExtensionIn / ExtensionOut
*       PARTNERADDRESSES     =
*       extensionex          = mt_extensionin. " ExtensionIn / ExtensionOut
      EXCEPTIONS
        error_message        = 99
        OTHERS               = 4.

    IF ls_import-i_commit NE space.
      IF sy-subrc EQ 0.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait   = 'X'
          IMPORTING
            return = ls_bapiret.

        IF ls_bapiret IS NOT INITIAL.
          INSERT ls_bapiret INTO mt_returns INDEX 1.
        ENDIF.
      ELSE.

        set_sysmsg_text( ).

        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
          IMPORTING
            return = ls_bapiret.
        IF ls_bapiret IS NOT INITIAL.
          INSERT ls_bapiret INTO mt_returns INDEX 1.
        ENDIF.
      ENDIF.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
        IMPORTING
          return = ls_bapiret.
      IF ls_bapiret IS NOT INITIAL.
        INSERT ls_bapiret INTO mt_returns INDEX 1.
      ENDIF.
    ENDIF.

    es_export = map_export( ).
    es_export-e_sessionid = is_import-i_sessionid.

  ENDMETHOD.
