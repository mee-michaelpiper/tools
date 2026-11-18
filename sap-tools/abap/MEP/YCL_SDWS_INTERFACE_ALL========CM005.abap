  METHOD check_matnr_werks.


    DATA lv_matnr TYPE matnr.

    " FIS/eu 300317 Gem. Absprache keine Konvertierung mehr! Ggf. auf Fehler laufen lassen!
*    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
*      EXPORTING
*        input        = iv_matnr
*      IMPORTING
*        output       = lv_matnr
*      EXCEPTIONS
*        length_error = 1
*        OTHERS       = 2.
*    IF sy-subrc <> 0.
*      lv_matnr = iv_matnr.
*    ENDIF.

    SELECT SINGLE matnr INTO @lv_matnr
    FROM marc
    WHERE matnr = @iv_matnr
    AND   werks = @iv_werks.
    IF sy-subrc <> 0.
      " Die Kombination Materialnummer/Werks &1/&2 esistiert nicht!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>matnr_werks_not_exist
          mv_matnr = iv_matnr
          mv_werks = iv_werks.

    ENDIF.

  ENDMETHOD.
