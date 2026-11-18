  METHOD get_flow_data.

    DATA  belegtyp TYPE vbtyp.
    DATA  comwa    TYPE vbco6.
    DATA  s_sdflow TYPE bapisdflow.
    DATA  t_vbfa   TYPE STANDARD TABLE OF vbfa.
    DATA  t_vbfap   TYPE STANDARD TABLE OF vbfa.
    DATA  t_item   TYPE ysdws_comitm_tt.

*    set_import_data_range( ).


    comwa-vbeln = ms_import-i_objky.

    LOOP AT ms_import-it_selopt ASSIGNING FIELD-SYMBOL(<posnr>)
      WHERE qualif = 'POSNR'.

*- Füllen der internen Struktur GL_VBFA pro Auftrag -------------------*
*- fill internal table GL_VBFA for each order -------------------------*
      comwa-posnr = <posnr>-fvalue.

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
          vbfa_tab      = t_vbfap
        EXCEPTIONS
          no_vbfa       = 1
          no_vbuk_found = 2
          error_message = 3
          OTHERS        = 4.

      APPEND LINES OF t_vbfap TO t_vbfa.
    ENDLOOP.

    IF sy-subrc NE 0.
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
    ENDIF.

    LOOP AT t_vbfa ASSIGNING FIELD-SYMBOL(<vbfa>).


      CLEAR t_item.
      comwa-posnr = sy-tabix.

      CALL FUNCTION 'MAP2E_VBFA_TO_BAPISDFLOW'
        EXPORTING
          vbfa       = <vbfa>
        CHANGING
          bapisdflow = s_sdflow.
      .

      export_to_item(
       EXPORTING
         iv_vakey = |{ comwa-posnr && 'BAPISDFLOW' }|
         is_quellstr  = s_sdflow
         iv_strnam    = 'BAPISDFLOW'
       RECEIVING
         et_item      = t_item ).

      APPEND LINES OF t_item TO es_export-et_item.
    ENDLOOP.

    CHECK t_vbfa[] IS INITIAL.

    " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = 'Angebote'(002).

  ENDMETHOD.
