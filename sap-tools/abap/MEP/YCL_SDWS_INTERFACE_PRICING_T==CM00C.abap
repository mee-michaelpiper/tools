  METHOD constructor.
    super->constructor( ).
    " Stücklistenprüfung - Ermittlung relevanter Positionstypengruppen.

    SELECT 'I'   AS sign,
           'EQ'  AS option,
           mtpos AS low
      INTO CORRESPONDING FIELDS OF TABLE @mr_stl
      FROM /fis/sd_set
      WHERE bposi = @abap_true.

    ms_import = is_import.

    IF ms_import-i_all_detail IS INITIAL.

      TRY.
          ycl_stvarvc=>get_selop( EXPORTING i_pname  = 'YSDWS_INTERFACE_PRICING'
                                            i_quali  = 'STUNR'
                                  IMPORTING et_selop = mr_relevant_stunr ).
        CATCH ycx_bc_err ##NO_HANDLER.
      ENDTRY.

    ENDIF.
  ENDMETHOD.
