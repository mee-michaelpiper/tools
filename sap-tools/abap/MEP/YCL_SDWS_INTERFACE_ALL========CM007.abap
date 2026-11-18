  METHOD check_werks.

    IF iv_werks IS INITIAL.
      " Das Werk konnte nicht ermittelt werden!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ycx_sdws_interface=>empty_werks.

    ENDIF.

    SELECT SINGLE werks INTO @DATA(lv_werks)
    FROM t001w
    WHERE werks = @iv_werks.
    IF sy-subrc <> 0.
      " Das Werk &1 ist unbekannt!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>werks_not_exist
          mv_werks = iv_werks.
    ENDIF.

  ENDMETHOD.
