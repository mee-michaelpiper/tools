  METHOD fetch_kuwe2.

    CLEAR ms_knvv.

    CALL FUNCTION 'VIEW_KNVV'
      EXPORTING
        comwa   = is_vtcom
      IMPORTING
        knvv_wa = rs_knvv
      EXCEPTIONS
        no_knvv = 1.

    IF sy-subrc NE 0.
      " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>kunnr_not_exist
          mv_kunnr = is_vtcom-kunnr
          mv_vkorg = is_vtcom-vkorg
          mv_vtweg = is_vtcom-vtweg
          mv_spart = is_vtcom-spart.
    ELSE.
      ms_knvv = rs_knvv.
    ENDIF.


  ENDMETHOD.
