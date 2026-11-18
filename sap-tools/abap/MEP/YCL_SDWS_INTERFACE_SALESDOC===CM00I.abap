  METHOD get_item_data.

    DATA t_vbap       TYPE STANDARD TABLE OF vbap.
    DATA t_vbep       TYPE STANDARD TABLE OF vbep.
    DATA s_bapisdit   TYPE  bapisdit.
    DATA s_bape_vbap  TYPE bape_vbap.

    DATA s_vbupvb     TYPE vbupvb.
    DATA s_bapisditst TYPE bapisditst.
    DATA v_msgv1      TYPE balmsgv1.
    DATA cond_syntax  TYPE string.

    cond_syntax = set_import_data_where( 'VBAP' ).

    SELECT        * INTO CORRESPONDING FIELDS OF TABLE t_vbap   "CI_SORTED
      FROM  vbap AS p
     INNER JOIN vbak AS k
      ON p~vbeln = k~vbeln
           WHERE  k~vbeln  = ms_import-i_objky
           AND    k~kunnr  = ms_import-i_kunnr
           AND    (cond_syntax).

    LOOP AT t_vbap ASSIGNING FIELD-SYMBOL(<vbap>).  "#EC CI_SORTED   "FISJl20200429 OSS336178 HANADB

      AT FIRST.                                               "#EC CI_SORTED
        SELECT * INTO CORRESPONDING FIELDS OF TABLE t_vbep    "#EC CI_SORTED
             FROM vbep
          FOR ALL ENTRIES IN t_vbap
          WHERE vbeln = t_vbap-vbeln
            AND posnr = t_vbap-posnr
            AND bmeng GT 0.
             ENDAT.

      SELECT SINGLE * INTO CORRESPONDING FIELDS OF s_vbupvb
         FROM  vbup
             WHERE  vbeln  = <vbap>-vbeln
             AND    posnr  = <vbap>-posnr.


      CALL FUNCTION 'MAP_VBUPVB_TO_BAPISDITST'
        EXPORTING
          vbupvb     = s_vbupvb
        CHANGING
          bapisditst = s_bapisditst.

      DATA(lt_item) = export_to_item(
      EXPORTING
        iv_vakey    = |{ <vbap>-posnr && 'ITEM' }|
       " iv_itmnumber = <vbap>-posnr
        is_quellstr  = s_bapisditst
        iv_strnam    = 'BAPISDITST' ).

      APPEND LINES OF lt_item TO es_export-et_item.
      CALL FUNCTION 'MAP2E_VBAP_TO_BAPISDIT'
        EXPORTING
          vbap     = <vbap>
        CHANGING
          bapisdit = s_bapisdit.

      lt_item = export_to_item(
      EXPORTING
        iv_vakey    = |{ <vbap>-posnr && 'ITEM' }|
        is_quellstr  = s_bapisdit
        iv_strnam    = 'BAPISDIT' ).
      APPEND LINES OF lt_item TO es_export-et_item.

      MOVE-CORRESPONDING <vbap> TO s_bape_vbap.

      lt_item = export_to_item(
    EXPORTING
      iv_vakey    = |{ <vbap>-posnr && 'ITEM' }|
      is_quellstr  = s_bape_vbap
      iv_strnam    = 'BAPE_VBAP' ).
      APPEND LINES OF lt_item TO es_export-et_item.

      IF ms_import-i_handle = 'GET_CONFIGURATIONS'
        AND <vbap>-cuobj NE space.

        DATA(t_conf) = get_configuration( <vbap>-cuobj ).
        set_conf_data( EXPORTING it_conf = t_conf iv_posnr = <vbap>-posnr
                    CHANGING ct_item = es_export-et_item ).

      ENDIF.

      set_sced_data( EXPORTING it_vbep = t_vbep
                              iv_posnr = <vbap>-posnr
                     CHANGING ct_item = es_export-et_item ).

    ENDLOOP.

    CHECK t_vbap IS INITIAL.

    IF i_vbtyp = 'C'.
      v_msgv1 = 'Aufträge'(001).
    ELSE.
      v_msgv1 = 'Angebote'(002).
    ENDIF.
    " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = v_msgv1.

  ENDMETHOD.
