  METHOD set_import_data_range.

    DATA ls_r_erdat LIKE LINE OF mt_sel_erdat.
    DATA lv_refnam TYPE string.
    DATA drefs TYPE REF TO data.
    DATA dreft TYPE REF TO data.
    DATA ls_sr_kunnr TYPE ysdws_kunnr_range.

    FIELD-SYMBOLS <sselvar> TYPE any.
    FIELD-SYMBOLS <selvar> TYPE ANY TABLE.

    LOOP AT ms_import-it_selopt ASSIGNING FIELD-SYMBOL(<selopt>).

      IF <selopt>-qualif = 'GLTAB'.
        mv_gltab = <selopt>-fvalue. CONTINUE.
      ELSEIF <selopt>-qualif = 'GLTBI'.
        mv_gltbi = <selopt>-fvalue. CONTINUE.
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
        WHEN 'FKDAT'.
          APPEND <sselvar> TO mt_sel_fkdat.
        WHEN 'KUNRG'.
          APPEND <sselvar> TO mt_sel_kunrg.
        WHEN 'NAME'.
          APPEND <sselvar> TO mt_sel_name.
        WHEN 'ORT'.
          APPEND <sselvar> TO mt_sel_ort.
        WHEN 'TELFN'.
          APPEND <sselvar> TO mt_sel_telfn.
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
        WHEN 'KDMAT'.
          APPEND <sselvar> TO mt_sel_kdmat.
      ENDCASE.

    ENDLOOP.

    IF ms_import-i_kunnr NE space.
      ls_sr_kunnr = 'IEQ'.
      ls_sr_kunnr-low = ms_import-i_kunnr.
      APPEND ls_sr_kunnr TO mt_sel_kunnr.
    ENDIF.

    IF mv_gltbi IS  INITIAL AND
      mv_gltab IS NOT INITIAL.
      mv_gltbi =  '99991231'.
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

    APPEND 'IEQF2' TO mt_sel_fkart.
  ENDMETHOD.
