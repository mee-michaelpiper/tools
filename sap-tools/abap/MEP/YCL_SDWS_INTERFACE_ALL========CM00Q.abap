  METHOD check_marm_entry.

    DATA(lv_meinh) = convert_iso_meins_so_sap_code( iv_vrkme_iso ).

    " Prüfung auf existierenden MARM-Eintrag
      SELECT SINGLE @abap_true
        INTO @DATA(lv_result)
        FROM marm WHERE matnr = @iv_matnr
        AND  meinh = @lv_meinh.

      IF sy-subrc <> 0.
        " Mengeneinheit &1(&2) nicht vorhanden zu Materialnummer &3!
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid          = ycx_sdws_interface=>marm_not_exist
            mv_isocode_unit = iv_vrkme_iso
            mv_vrkme        = lv_meinh
            mv_matnr        = iv_matnr.
      ENDIF.

  ENDMETHOD.
