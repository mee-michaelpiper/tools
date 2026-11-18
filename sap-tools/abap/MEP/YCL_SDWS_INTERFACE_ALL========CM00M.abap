  METHOD get_material_vrkme.

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

    SELECT SINGLE vrkme INTO rv_meinh
    FROM mvke
    WHERE matnr = iv_matnr
    AND   vkorg = lv_vkorg
    AND   vtweg = lv_vtweg.

    IF sy-subrc <> 0 OR rv_meinh IS INITIAL.
      SELECT SINGLE meins INTO rv_meinh
      FROM mara
      WHERE matnr = iv_matnr.
    ENDIF.

  ENDMETHOD.
