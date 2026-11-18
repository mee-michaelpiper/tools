  METHOD export_class.

    DATA lt_klart TYPE TABLE OF  rmclklart.
    DATA ls_return_o TYPE ysdws_return_e_s.

    CALL FUNCTION 'CLCA_GET_CLASSTYPES_FROM_TABLE'
      EXPORTING
        spras              = sy-langu
        table              = ms_import-class_objtbl
        with_text          = abap_true
        with_refresh       = abap_true
      TABLES
        iklart             = lt_klart
      EXCEPTIONS
        no_classtype_found = 0.

    SELECT * INTO TABLE @DATA(t_kssk) FROM  kssk
      FOR ALL ENTRIES IN @lt_klart
           WHERE  objek  = @ms_import-i_objky
           AND    klart  = @lt_klart-klart
          " AND   ( datuv  LE @sy-datlo or datuv is initial )
           AND    lkenz  = @space.
        "   AND   ( datub  GE @sy-datlo or datub eq @space ).

    LOOP AT t_kssk ASSIGNING FIELD-SYMBOL(<kssk>).

      ms_import-classtype = <kssk>-klart.
     TRY.
      read_mat_classification_detail( ms_import ).

      APPEND LINES OF mo_class->t_alloclist TO es_class-et_list.
      APPEND LINES OF mo_class->t_allocvalueschar TO es_class-et_vchar.
      APPEND LINES OF mo_class->t_allocvaluescurr TO es_class-et_vcurr.
      APPEND LINES OF mo_class->t_allocvaluesnum  TO es_class-et_vnum.

* Meldungen zurückgeben
      LOOP AT mo_class->t_return ASSIGNING FIELD-SYMBOL(<return>).
        CLEAR ls_return_o.
        ls_return_o-type = <return>-type.
        ls_return_o-message = <return>-message.
        ls_return_o-posnr = <return>-row.
        APPEND ls_return_o TO et_returns.
      ENDLOOP.


      CATCH ycx_sdws_interface .
     ENDTRY.
      FREE mo_class.

    ENDLOOP.


  ENDMETHOD.
