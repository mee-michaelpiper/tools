  METHOD get_item_data.

    DATA t_vbap     TYPE STANDARD TABLE OF vbap.
    DATA s_bapisdit TYPE  bapisdit.
    DATA s_bape_vbap TYPE bape_vbap.
    DATA cond_syntax TYPE string.

    cond_syntax = set_import_data_where( 'VBAP' ).

    SELECT        * INTO CORRESPONDING FIELDS OF TABLE t_vbap
      FROM  vbap AS p
     INNER JOIN vbak AS k
      ON p~vbeln = k~vbeln
           WHERE  k~vbeln  = ms_import-i_objky
           AND    k~kunnr  = ms_import-i_kunnr
           AND    (cond_syntax).

    LOOP AT t_vbap ASSIGNING FIELD-SYMBOL(<vbap>).

      CALL FUNCTION 'MAP2E_VBAP_TO_BAPISDIT'
        EXPORTING
          vbap     = <vbap>
        CHANGING
          bapisdit = s_bapisdit.

      export_to_item(
    EXPORTING
      iv_itmnumber = <vbap>-posnr
      is_quellstr  = s_bapisdit
      iv_strnam    = 'BAPISDIT'
    RECEIVING
      et_item      = es_export-et_item ).

      MOVE-CORRESPONDING <vbap> TO s_bape_vbap.

      export_to_item(
    EXPORTING
      iv_itmnumber = <vbap>-posnr
      is_quellstr  = s_bape_vbap
      iv_strnam    = 'BAPE_VBAP'
    RECEIVING
      et_item      = es_export-et_item ).

    ENDLOOP.

    CHECK t_vbap IS INITIAL.

    " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = 'Angebote'(002).

  ENDMETHOD.
