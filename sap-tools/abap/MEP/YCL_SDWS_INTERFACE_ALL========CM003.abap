  METHOD check_kunnr.

    DATA lv_kunnr TYPE kna1-kunnr.

    IF iv_kunnr IS INITIAL.
      " Die Kundennummer muss befüllt sein!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ycx_sdws_interface=>empty_kunnr.
    ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = iv_kunnr    " C-Feld
      IMPORTING
        output = lv_kunnr.    " interne Darstellung von INPUT, beliebiger Typ

    IF iv_vkorg IS NOT INITIAL.
      DATA(lv_vkorg) = iv_vkorg.
    ELSE.
      lv_vkorg = mc_default_vkorg.
    ENDIF.

    IF iv_vtweg IS NOT INITIAL.
      DATA(lv_vtweg) = iv_vtweg.
    ELSE.
      lv_vtweg = mc_default_vtweg.
    ENDIF.

    IF iv_spart IS NOT INITIAL.
      DATA(lv_spart) = iv_spart.
    ELSE.
      lv_spart = mc_default_spart.
    ENDIF.

    SELECT SINGLE vwerk INTO rv_kun_werks
    FROM knvv
    WHERE kunnr = lv_kunnr
    AND   vkorg = lv_vkorg
    AND   vtweg = lv_vtweg
    AND   spart = lv_spart.
    IF sy-subrc <> 0.
      " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>kunnr_not_exist
          mv_kunnr = iv_kunnr
          mv_vkorg = lv_vkorg
          mv_vtweg = lv_vtweg
          mv_spart = lv_spart.

    ENDIF.
  ENDMETHOD.
