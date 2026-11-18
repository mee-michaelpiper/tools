  METHOD get_knvp.
    "      ls_komk-yy_kunya = get_knvp( is_import = is_import is_pispr = ls_pispr )-kunn2.

    " Aussendienstmitarbeiter

    SELECT * INTO rs_knvp
      UP TO 1 ROWS     " FISJL20200429  OSS336178  HANADB
      FROM knvp
      WHERE kunnr = is_import-i_kunnr
        AND vkorg = is_pispr-vkorg
        AND vtweg = is_pispr-vtweg
        AND spart = is_pispr-spart
        AND parvw = ycl_sdbf=>mc_parvw_ya
      ORDER BY PRIMARY KEY.
    ENDSELECT.
  ENDMETHOD.
