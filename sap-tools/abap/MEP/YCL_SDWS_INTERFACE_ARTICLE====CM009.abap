  METHOD set_import_data_range.

    DATA ls_matnr TYPE LINE OF ycl_sdws_interface_all=>tty_sel_matnr.
    DATA ls_leada TYPE ysdws_rs_laeda.
    DATA ls_ersda TYPE ysdws_rs_ersda.

    LOOP AT is_import-it_selopt ASSIGNING FIELD-SYMBOL(<sel>).
*
      CASE <sel>-qualif.
        WHEN 'MATNR'.
          IF <sel>-fvalue CA '*+'.
            ls_matnr = 'ICP'.
          ELSE.
            ls_matnr = 'IEQ'.
          ENDIF.
          ls_matnr-low = <sel>-fvalue.
          APPEND ls_matnr TO mt_sel_matnr.

        WHEN 'LEAAB'.
          ls_leada-low = <sel>-fvalue.
        WHEN 'LEABI'.
          ls_leada-high = <sel>-fvalue.
        WHEN  'ERFAB'.
          ls_ersda-low = <sel>-fvalue.
        WHEN 'ERFBI'.
          ls_ersda-high = <sel>-fvalue.
        when 'CLASS_OBJTBL'.
          is_import-CLASS_OBJTBL = <SEL>-fvalue.
      ENDCASE.
*
    ENDLOOP.

    IF ls_leada IS NOT INITIAL.
      ls_leada-sign = 'I'.
      ls_leada-option = 'BT'.
      IF ls_leada-low IS INITIAL.
        ls_leada-low = '19000101'.
      ELSEIF ls_leada-high IS INITIAL.
        ls_leada-high = '99991231'.
      ENDIF.
      APPEND ls_leada TO mt_sel_laeda.
    ENDIF.

    IF ls_ersda IS NOT INITIAL.
      ls_ersda-sign = 'I'.
      ls_ersda-option = 'BT'.
      IF ls_ersda-low IS INITIAL.
        ls_ersda-low = '19000101'.
      ELSEIF ls_ersda-high IS INITIAL.
        ls_ersda-high = '99991231'.
      ENDIF.
      APPEND ls_ersda TO mt_sel_ersda.
    ENDIF.

  ENDMETHOD.
