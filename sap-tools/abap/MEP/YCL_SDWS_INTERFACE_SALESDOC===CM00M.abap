  METHOD set_sced_data.
    DATA s_bapisdhedu TYPE bapisdhedu.

    LOOP AT it_vbep ASSIGNING FIELD-SYMBOL(<vbep>)
  WHERE posnr = iv_posnr.

      CALL FUNCTION 'MAP2E_VBEP_TO_BAPISDHEDU'
        EXPORTING
          vbep       = <vbep>
        CHANGING
          bapisdhedu = s_bapisdhedu.

      DATA(lt_item) = export_to_item(
      EXPORTING
        iv_vakey    = |{ <vbep>-posnr && 'SCED' && <vbep>-etenr }|
        is_quellstr  = s_bapisdhedu
        iv_strnam    = 'BAPISDHEDU' ).
      APPEND LINES OF lt_item TO ct_item.
    ENDLOOP.

  ENDMETHOD.
