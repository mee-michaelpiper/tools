  METHOD check_kalsm.

    SELECT SINGLE kalsm INTO @DATA(lv_kalsm)
    FROM t683
    WHERE kvewe = @mc_kvewe_a
    AND   kappl = @mc_kappl_v
    AND   kalsm = @iv_kalsm.
    IF sy-subrc <> 0.

      " Kalkulationsschema &1 unbekannt!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>kalsm_not_exist
          mv_kalsm = iv_kalsm.

    ENDIF.
  ENDMETHOD.
