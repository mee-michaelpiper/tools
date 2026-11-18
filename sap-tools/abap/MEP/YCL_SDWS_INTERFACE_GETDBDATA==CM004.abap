  METHOD get_data.
*-----------------------------------------------------------------------
* Changes                                                   |patch
* Name      |Date                                           |K-Korrektur
* Description:                                              |C-ChangeReq
*-----------------------------------------------------------------------
*Leutbecher|12.04.2021                                      |K359240
*Problem  call SE16N_INTERFACE ohne Treffer bildet keine Refernz
*darauffolgnder Zugriff führt zum Dump
*Lösung: Ausnahme wird geworfen, so das ine Meldung zurückgeliefert wird
*-----------------------------------------------------------------------

    DATA: l_dref            TYPE REF TO data.
    DATA: lrf_components TYPE REF TO cl_abap_structdescr.
    DATA: lt_selfields      TYPE TABLE OF se16n_seltab.
    DATA: lt_output_fields  TYPE se16n_output_t.

    FIELD-SYMBOLS: <response>      TYPE table.

    CLEAR mv_number_of_documents.

    ms_import-in = is_import.
    get_default_values( EXPORTING iv_strname = 'YSDWS_DFLT_S'
                    changing cs_zielstr = ms_import ).
    lrf_components ?= get_ref_components_of( ).
    check_ifields( lrf_components ).
    lt_selfields = set_dynamic_where( ms_import-in ).
    check_ofields( EXPORTING if_tdescr = lrf_components
                    CHANGING ct_fields = ms_import-in-it_ofields ).


*.call SE16N_INTERFACE to select all lines in SFLIGHT with Carrier LH
*.but do not display the found lines
    CALL FUNCTION 'SE16N_INTERFACE'
      EXPORTING
        i_tab            = ms_import-in-i_tabname
        i_max_lines      = ms_import-in-i_max_lines
        i_clnt_dep       = abap_true
        i_add_fields_on      = abap_true
        i_display        = space
      IMPORTING
        e_dref           = l_dref
      TABLES
        it_output_fields = ms_import-in-it_ofields
*"      IT_OR_SELFIELDS TYPE  SE16N_OR_T OPTIONAL
        it_selfields     = lt_selfields
      EXCEPTIONS
        no_values        = 1.

    if sy-subrc ne 0.           "K359240
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid   = ycx_sdws_interface=>DATA_NOT_FOUND.
    endif.                      "K359240
    FIELD-SYMBOLS <value> TYPE any.
*.get pointer to selected data
    ASSIGN l_dref->* TO <response>.

    LOOP AT <response> ASSIGNING FIELD-SYMBOL(<line>).

      ADD 1 TO mv_number_of_documents.
      LOOP AT ms_import-in-it_ofields ASSIGNING FIELD-SYMBOL(<field>).

        ASSIGN COMPONENT <field> OF STRUCTURE <line> TO <value>.
        IF sy-subrc EQ 0.
          APPEND INITIAL LINE TO es_export-et_item ASSIGNING FIELD-SYMBOL(<exp_line>).
          <exp_line>-vakey = mv_number_of_documents.
          <exp_line>-qualif = <field>.
          <exp_line>-fvalue = <value>.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    es_export-et_header = append_header_data(
       EXPORTING i_qualifier = 'NUMBER_OF_DOCUMENTS' i_fvalue = mv_number_of_documents ).

  ENDMETHOD.
