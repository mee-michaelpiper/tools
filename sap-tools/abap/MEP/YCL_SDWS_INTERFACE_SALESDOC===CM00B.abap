  METHOD GET_KUWE2.
    DATA: vtcom     TYPE vtcom.

    CLEAR vtcom.
    vtcom-kunnr = iv_kunnr.
    vtcom-parvw = iv_parvw.
    vtcom-vkorg = iv_vkorg.
    vtcom-vtweg = iv_vtweg.
    vtcom-spart = iv_spart.

    call function 'VIEW_KUWE2'
      exporting
        comwa   = vtcom
      importing
        wewa    = es_kunwa
      exceptions
        no_kna1 = 1
        no_knvv = 2.

    CHECK sy-subrc NE 0.
    " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>kunnr_not_exist
        mv_kunnr = iv_kunnr
        mv_vkorg = iv_vkorg
        mv_vtweg = iv_vtweg
        mv_spart = iv_spart.

  ENDMETHOD.
