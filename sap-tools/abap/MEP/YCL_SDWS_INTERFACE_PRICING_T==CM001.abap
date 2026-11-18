  METHOD convert_matnr.
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING  input        = iv_matnr
      IMPORTING  output       = rv_matnr
      EXCEPTIONS length_error = 1
                 OTHERS       = 2.
    IF sy-subrc <> 0.
      " Materialnummer &1 ist unbekannt!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING textid   = ycx_sdws_interface=>matnr_not_exist
                  mv_matnr = iv_matnr.
    ENDIF.
  ENDMETHOD.
