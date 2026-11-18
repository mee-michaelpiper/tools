METHOD export_bapi_extensions.
  DATA dref_itm    TYPE REF TO data.
  DATA ls_item     TYPE ysdws_comitm_s.
  DATA ls_header   TYPE ysdws_comhdr_s.
  DATA ls_itmvakey TYPE ty_itmvakey.
  DATA lv_lgkey    TYPE i.

  lv_lgkey = strlen( iv_vakey ).


  LOOP AT mt_extensionex ASSIGNING FIELD-SYMBOL(<itm>)
    WHERE structure = iv_strname.

    CHECK <itm>-valuepart1(lv_lgkey) = iv_vakey(lv_lgkey).

    CREATE DATA dref_itm TYPE (<itm>-structure).
    ASSIGN dref_itm->* TO FIELD-SYMBOL(<wa>).
    <wa> = <itm>+30.
    IF abap_true = check_kommitxt_in_sel( <wa> ).
      LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
        WHERE strname = <itm>-structure.
        ls_item-vakey = iv_vakey(lv_lgkey).
        ls_item-qualif = <opt>-fieldname.
        ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE <wa> TO FIELD-SYMBOL(<value>).
        IF <value> IS ASSIGNED.
          WRITE <value> TO ls_item-fvalue.
        ELSE.
          ls_item-fvalue = 'NOT_ASSIGNED'.
        ENDIF.

        APPEND ls_item TO et_item.

        UNASSIGN <value>.
      ENDLOOP.
    ELSE.
      DELETE et_item WHERE vakey = iv_vakey(lv_lgkey).
    ENDIF.

  ENDLOOP.


ENDMETHOD.
