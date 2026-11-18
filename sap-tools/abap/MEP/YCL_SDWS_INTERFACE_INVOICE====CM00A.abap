  METHOD get_flow_data.

    DATA  belegtyp TYPE vbtyp.
    DATA  comwa    TYPE vbco6.
    DATA  t_vbfa   TYPE STANDARD TABLE OF vbfa.


*    set_import_data_range( ).


    comwa-vbeln = ms_import-i_objky.
*- Füllen der internen Struktur GL_VBFA pro Auftrag -------------------*
*- fill internal table GL_VBFA for each order -------------------------*

    CALL FUNCTION 'RV_ORDER_FLOW_INFORMATION'
      EXPORTING
        belegtyp      = i_vbtyp "belegtyp
        comwa         = comwa
        nachfolger    = ms_import-nachfolger
        n_stufen      = ms_import-nstufen
        vorgaenger    = ms_import-vorgaenger
        v_stufen      = ms_import-vstufen
        no_acc_doc    = ms_import-no_acc_doc
      TABLES
        vbfa_tab      = t_vbfa
      EXCEPTIONS
        no_vbfa       = 1
        no_vbuk_found = 2
        error_message = 3
        OTHERS        = 4.


    LOOP AT t_vbfa ASSIGNING FIELD-SYMBOL(<vbfa>).

      comwa-posnr = sy-tabix.

      export_to_item(
       EXPORTING
         iv_itmnumber = comwa-posnr
         is_quellstr  = <vbfa>
         iv_strnam    = 'VBFA'
       RECEIVING
         et_item      = es_export-et_item ).


    ENDLOOP.

    CHECK t_vbfa[] IS INITIAL.

    " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = 'Angebote'(002).

  ENDMETHOD.
