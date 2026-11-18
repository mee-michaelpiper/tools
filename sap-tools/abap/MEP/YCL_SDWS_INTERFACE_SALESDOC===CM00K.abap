  METHOD check_posnr_in_sel.

    rv_result = abap_true.
    LOOP AT ms_import-it_selopt ASSIGNING FIELD-SYMBOL(<sel>)
      WHERE qualif = 'POSNR'.

      IF iv_posnr = <sel>-fvalue.
        rv_result = abap_true.
      ENDIF.
    ENDLOOP.
    CHECK sy-subrc NE 0.
    rv_result = abap_true.

  ENDMETHOD.
