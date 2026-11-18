  METHOD check_matnr.

    DATA lv_matnr TYPE matnr.

    IF iv_matnr IS INITIAL.
      " Die Materialnummer muss befüllt sein.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ycx_sdws_interface=>empty_matnr.
    ENDIF.

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

    SELECT SINGLE matnr INTO lv_matnr
    FROM mara
    WHERE matnr = iv_matnr.

    IF sy-subrc <> 0.
      " Materialnummer &1 ist unbekannt!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>matnr_not_exist
          mv_matnr = iv_matnr.
    ENDIF.
  ENDMETHOD.
