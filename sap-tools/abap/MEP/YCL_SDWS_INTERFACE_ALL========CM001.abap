  METHOD check_iso_code_unit.

    IF iv_iso_code IS NOT INITIAL.
      SELECT SINGLE isocode INTO @DATA(lv_isocode)
      FROM t006i
      WHERE isocode = @iv_iso_code.
      IF sy-subrc <> 0.

        " Der ISO-Code (Mengeneinheit): &1 existiert nicht!
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid          = ycx_sdws_interface=>isocode_unit_not_exist
            mv_isocode_unit = iv_iso_code.
      ENDIF.
    ENDIF.

  ENDMETHOD.
