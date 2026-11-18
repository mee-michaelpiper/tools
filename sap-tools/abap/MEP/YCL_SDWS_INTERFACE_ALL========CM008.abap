  METHOD convert_iso_meins_so_sap_code.

    CALL FUNCTION 'UNIT_OF_MEASURE_ISO_TO_SAP'
      EXPORTING
        iso_code  = iv_isocode_unit    " ISO-Code für die Maßeinheit
      IMPORTING
        sap_code  = rv_msehi    " SAP-Code für die Maßeinheit
*       unique    =     " X-Feld: ISO-Code -> SAP-Code ist eindeutig
      EXCEPTIONS
        not_found = 1
        OTHERS    = 2.
    IF sy-subrc <> 0.
      " Der ISO-Code (Mengeneinheit): &1 existiert nicht!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid          = ycx_sdws_interface=>isocode_unit_not_exist
          mv_isocode_unit = iv_isocode_unit.
    ENDIF.



  ENDMETHOD.
