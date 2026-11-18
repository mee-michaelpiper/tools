  METHOD get_marm.
    SELECT * INTO TABLE rt_marm  "#EC CI_SORTED
      FROM marm
      WHERE matnr = iv_matnr.
  ENDMETHOD.
