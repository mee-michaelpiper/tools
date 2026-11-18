  METHOD check_auart.
    IF iv_auart IS NOT INITIAL.

      SELECT SINGLE auart INTO @DATA(lv_auart)
      FROM tvak
      WHERE auart = @iv_auart.
      IF sy-subrc <> 0.

        " Die Auftragsart &1 ist unbekannt!
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid   = ycx_sdws_interface=>auart_not_exist
            mv_auart = iv_auart.

      ENDIF.
    ENDIF.

  ENDMETHOD.
