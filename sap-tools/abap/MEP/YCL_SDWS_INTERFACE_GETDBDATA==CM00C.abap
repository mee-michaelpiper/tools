  METHOD get_ref_components_of.

*    rf_tdescr ?= cl_abap_typedescr=>describe_by_name(  ms_import-in-i_tabname ).
    cl_abap_typedescr=>describe_by_name(
      EXPORTING
        p_name         = ms_import-in-i_tabname
      RECEIVING
        p_descr_ref    = rf_tdescr
      EXCEPTIONS
        type_not_found = 1
        OTHERS         = 2 ).
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>no_data_object
          mv_msgv1 = CONV #( |{ 'Tabelle:' && ms_import-in-i_tabname }| ).

    ENDIF.

  ENDMETHOD.
