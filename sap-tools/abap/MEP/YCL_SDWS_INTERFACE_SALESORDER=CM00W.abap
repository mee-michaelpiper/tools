  METHOD fill_bapi_cfgs.

    ms_cfgs = is_cfgs.

    LOOP AT ms_cfgs-t_ref ASSIGNING FIELD-SYMBOL(<ref>).
      READ TABLE mt_order_items_in WITH KEY po_itm_no = <ref>-posex
      ASSIGNING FIELD-SYMBOL(<itm>).
      IF sy-subrc EQ 0 AND <itm> IS ASSIGNED.
        READ TABLE mt_order_items_inx WITH KEY itm_number = <itm>-itm_number
        ASSIGNING FIELD-SYMBOL(<itmx>).
        IF sy-subrc EQ 0 AND <itmx> IS ASSIGNED.
          <itmx>-config_id = abap_true.
          <itmx>-inst_id = abap_true.
        ELSE.
          RAISE EXCEPTION TYPE ycx_sdws_interface
            EXPORTING
              textid   = ycx_sdws_interface=>config_ref_rong
              mv_msgv1 = CONV balmsgv1( <ref>-posex ).

        ENDIF.
      ELSE.
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid   = ycx_sdws_interface=>config_ref_rong
            mv_msgv1 = CONV balmsgv1( <ref>-posex ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.
