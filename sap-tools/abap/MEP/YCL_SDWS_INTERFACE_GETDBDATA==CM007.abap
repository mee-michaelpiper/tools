  METHOD SET_IMPORT_DATA_WHERE.

*    DATA dref TYPE REF TO data.
*    DATA lv_squalif TYPE /fisxee/qualf.
*    FIELD-SYMBOLS <deflt> TYPE any.
*
*    CREATE DATA dref TYPE (iv_strnam).
*    ASSIGN dref->* TO FIELD-SYMBOL(<lf_str>).
*
*    SORT ms_import-it_selopt.
*
*
*    LOOP AT ms_import-it_selopt ASSIGNING FIELD-SYMBOL(<selopt>).
*
*      IF <selopt>-qualif NE lv_squalif.
*        lv_squalif = <selopt>-qualif.
*        IF rv_cond_syntax NE space.
*          rv_cond_syntax = rv_cond_syntax && ') AND'.
*        ENDIF.
*        UNASSIGN <deflt>.
*        ASSIGN COMPONENT <selopt>-qualif OF STRUCTURE <lf_str> TO <deflt>.
*        CHECK <deflt> IS ASSIGNED.
*        rv_cond_syntax = rv_cond_syntax && ' ' && <selopt>-qualif && ' in ('''.
*      ENDIF.
*
*      rv_cond_syntax = rv_cond_syntax && <selopt>-fvalue && ''''.
*
*    ENDLOOP.
*
*    IF sy-subrc EQ 0.
*      rv_cond_syntax = rv_cond_syntax && ' )'.
*    ENDIF.
  ENDMETHOD.
