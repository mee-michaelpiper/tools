  METHOD read_inforecord.

    DATA(flifn) = search_source_of_supply(
    EXPORTING
      iv_werks = ms_import-plant
      iv_matnr = iv_matnr ).

*    SELECT SINGLE * INTO eina FROM  eina
*           WHERE  matnr  = iv_matnr
*           AND    lifnr  = flifn.
    SELECT * INTO eina FROM  eina UP TO 1 ROWS      "FISJL20200429  OSS336178  HANADB
     WHERE  matnr  = iv_matnr
      AND   lifnr  = flifn ORDER BY PRIMARY KEY.
    ENDSELECT.



  ENDMETHOD.
