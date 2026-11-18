  METHOD check_import_data.

    DATA lv_msgv1 TYPE BALMSGV1.
    DATA lv_msgv2 TYPE BALMSGV1.

    SELECT        * INTO ms_tnapr FROM  tnapr   "#EC CI_NOORDER    "FISJL20200429  OSS336178  HANADB
           WHERE  kschl  = iv_kschl
           and   NACHA = '2'.

    ENDSELECT.

    IF sy-dbcnt GT 1.
      lv_msgv1 = iv_kschl.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>msg_not_clearly
          mV_Msgv1 = lv_msgv1.


    ENDIF.

*    SELECT single       * into ms_t685t FROM  t685t
*           WHERE  spras  = iv_spras
*           AND    kschl  = iv_kschl.
    SELECT * into ms_t685t FROM t685t UP TO 1 ROWS   "FISJL20200429 OSS336178 HANADB
     WHERE  spras  = iv_spras
      AND   kschl  = iv_kschl ORDER BY PRIMARY KEY.
   ENDSELECT.


    SELECT * FROM  nast INTO ms_nast UP TO 1 ROWS    "FISJl20200429 OSS336178 HANADB
     WHERE  kappl  = ms_tnapr-kappl
      and   objky  = iv_objky
      AND   kschl  = ms_tnapr-kschl
      AND   parnr  = iv_kunnr ORDER BY PRIMARY KEY.
   ENDSELECT.

    IF sy-subrc NE 0.
      lv_msgv1 =  ms_t685t-vtext && iv_objky.
      lv_msgv2 =  iv_kunnr.

      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>document_not_found
         mv_msgv1 = lv_msgv1
         mv_msgv2 = lv_msgv2.
    ENDIF.

    ms_nast-sort1 = 'EBPP'.
    ms_nast-TDARMOD = '1'.

  ENDMETHOD.
