  METHOD get_supplierdata.


    SELECT SINGLE * INTO lfa1 FROM  lfa1
           WHERE  lifnr  = is_import-lifnr.

    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid        = ycx_sdws_interface=>general_no_data
          mv_session_id = is_import-i_sessionid.

    ENDIF.

    IF is_import-ekorg NE space.
      SELECT SINGLE       * INTO lfm1 FROM  lfm1
             WHERE  lifnr  = is_import-lifnr
             AND    ekorg  = is_import-ekorg.

      IF sy-subrc NE 0.
*       Meldung Aufnehmen

      ENDIF.
    ENDIF.

    CHECK lfa1-adrnr NE space.
* Ermitteln der Adressdaten
    CALL FUNCTION 'ADDR_GET_COMPLETE'
      EXPORTING
        addrnumber        = lfa1-adrnr
      IMPORTING
        addr1_complete    = ms_addr1_complete
      EXCEPTIONS
        parameter_error   = 1
        address_not_exist = 2
        internal_error    = 3
        OTHERS            = 4.

  ENDMETHOD.
