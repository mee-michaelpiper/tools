  METHOD set_import_data_range.

    DATA ls_r_erdat LIKE LINE OF mt_sel_erdat.
    DATA ls_r_fkdat LIKE LINE OF mt_sel_fkdat.
    DATA lv_refnam TYPE string.
    DATA drefs TYPE REF TO data.
    DATA dreft TYPE REF TO data.

    FIELD-SYMBOLS <sselvar> TYPE any.
    FIELD-SYMBOLS <selvar> TYPE ANY TABLE.

    LOOP AT ms_import-it_selopt ASSIGNING FIELD-SYMBOL(<selopt>).

      IF <selopt>-qualif = 'FKDAB'.
        mv_fkdab = <selopt>-fvalue. CONTINUE.
      ELSEIF <selopt>-qualif = 'FKDBI'.
        mv_fkdbi = <selopt>-fvalue. CONTINUE.
      ENDIF.

      IF <selopt>-qualif = 'ERFAB'.
        mv_erfab = <selopt>-fvalue. CONTINUE.
      ELSEIF <selopt>-qualif = 'ERFBI'.
        mv_erfbi = <selopt>-fvalue. CONTINUE.
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
        WHEN 'AUBEL'.
          APPEND <sselvar> TO mt_sel_aubel.
      ENDCASE.

    ENDLOOP.




    IF mv_fkdab IS NOT INITIAL.
      ls_r_fkdat = 'IBT'.
      ls_r_fkdat-low = mv_fkdab.
      IF mv_fkdbi IS NOT INITIAL.
        ls_r_fkdat-high = mv_fkdbi.
      ELSE.
        ls_r_fkdat-high = '99991231'.
      ENDIF.
      APPEND ls_r_fkdat TO mt_sel_fkdat.
    ELSEIF mv_fkdbi IS NOT INITIAL.
      ls_r_fkdat = 'IBT'.
      ls_r_fkdat-high = mv_fkdbi.
      ls_r_fkdat-low = '10000101'.
      APPEND ls_r_fkdat TO mt_sel_fkdat.
    ENDIF.


    IF mv_erfab IS NOT INITIAL.
      ls_r_erdat = 'IBT'.
      ls_r_erdat-low = mv_erfab.
      IF mv_erfbi IS NOT INITIAL.
        ls_r_erdat-high = mv_erfbi.
      ELSE.
        ls_r_erdat-high = '99991231'.
      ENDIF.
      APPEND ls_r_erdat TO mt_sel_erdat.
    ELSEIF mv_erfbi IS NOT INITIAL.
      ls_r_erdat = 'IBT'.
      ls_r_erdat-high = mv_erfbi.
      ls_r_erdat-low = '10000101'.
      APPEND ls_r_erdat TO mt_sel_erdat.
    ENDIF.


  ENDMETHOD.
