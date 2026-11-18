  METHOD set_import_data_range.

    DATA ls_r_erdat LIKE LINE OF mt_sel_erdat.
    DATA ls_r_aufnr LIKE LINE OF mt_sel_aufnr.
    DATA ls_r_lfdat LIKE LINE OF mt_sel_lfdat.
    DATA lv_refnam TYPE string.
    DATA drefs TYPE REF TO data.
    DATA dreft TYPE REF TO data.

    FIELD-SYMBOLS <sselvar> TYPE any.
    FIELD-SYMBOLS <selvar> TYPE ANY TABLE.

    LOOP AT ms_import-it_selopt ASSIGNING FIELD-SYMBOL(<selopt>).

      lv_refnam = |{ 'MV_' && <selopt>-qualif }|.
      ASSIGN (lv_refnam) TO FIELD-SYMBOL(<ref>).
      IF <ref> IS ASSIGNED.
        <ref> = <selopt>-fvalue. UNASSIGN <ref>. CONTINUE.
      ENDIF.


      IF <selopt>-fvalue CA '*+'.
        mv_option = 'CP'.
      ELSE.
        mv_option = 'EQ'.
      ENDIF.

      lv_refnam = 'MT_SEL_' && <selopt>-qualif.

      UNASSIGN: <sselvar>, <selvar>.
      TRY.
          ASSIGN (lv_refnam) TO <selvar>.
          CHECK <selvar> IS ASSIGNED.

          CREATE DATA drefs LIKE LINE OF <selvar>.
          ASSIGN drefs->* TO <sselvar>.
*          CREATE DATA dreft TYPE TABLE OF (lv_refnam).
*          ASSIGN dreft->* TO <selvar>.

        CATCH cx_sy_create_data_error.

      ENDTRY.


      ASSIGN COMPONENT 'LOW' OF STRUCTURE <sselvar> TO FIELD-SYMBOL(<ziel>).
      <ziel> = <selopt>-fvalue.
      ASSIGN COMPONENT 'SIGN' OF STRUCTURE <sselvar> TO <ziel>.
      <ziel> = mc_sign.
      ASSIGN COMPONENT 'OPTION' OF STRUCTURE <sselvar> TO <ziel>.
      <ziel> =  mv_option.

      CASE <selopt>-qualif.
        WHEN 'BSTKD'.
          APPEND <sselvar> TO mt_sel_bstkd.
        WHEN 'KOMMI'.
          APPEND <sselvar> TO mt_sel_kommi.
        WHEN 'MATNR'.
          APPEND <sselvar> TO mt_sel_matnr.
        WHEN 'VBELN'.
          APPEND <sselvar> TO mt_sel_vbeln.
        WHEN 'BSTNK'.
          APPEND <sselvar> TO mt_sel_bstnk.
        WHEN 'AUFNR'.
          APPEND <sselvar> TO mt_sel_aufnr.
      ENDCASE.

    ENDLOOP.

    APPEND |{ 'IEQ' && ms_import-i_kunnr }| TO mt_sel_kunnr.
    APPEND |{ 'IEQ' && ms_import-i_vkorg }| TO mt_sel_vkorg.
    APPEND |{ 'IEQ' && ms_import-i_vtweg }| TO mt_sel_vtweg.


    IF mv_lfdab IS NOT INITIAL.
      IF mv_lfdbi IS INITIAL.
        mv_lfdbi = '99991231'.
      ENDIF.
      APPEND |{ 'IBT' && mv_lfdab && mv_lfdbi }| TO mt_sel_lfdat.
    ELSEIF mv_lfdbi IS NOT INITIAL.
      mv_lfdab = '10000101'.
      APPEND |{ 'IBT' && mv_lfdab && mv_lfdbi }| TO mt_sel_lfdat.
    ENDIF.

    IF mv_erfab IS NOT INITIAL.
      IF mv_erfbi IS INITIAL.
        mv_erfbi = '99991231'.
      ENDIF.
      APPEND |{ 'IBT' && mv_erfab && mv_erfbi }| TO mt_sel_erdat.
    ELSEIF mv_erfbi IS NOT INITIAL.
      mv_erfab = '10000101'.
      APPEND |{ 'IBT' && mv_erfab && mv_erfbi }| TO mt_sel_erdat.
    ENDIF.


  ENDMETHOD.
