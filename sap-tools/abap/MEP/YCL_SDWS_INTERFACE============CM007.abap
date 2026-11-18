  METHOD export_to_item.

    DATA: ls_item     TYPE ysdws_comitm_s,
          ls_itemt    TYPE ysdws_comitm_s,
          ls_itmvakey TYPE ty_itmvakey.

*    ls_itmvakey-itm_number = iv_itmnumber.
*    ls_itmvakey-itm_obj    = iv_strnam(4).
*   " ls_itmvakey-itm_key
    ls_itmvakey = iv_vakey.

    LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
      WHERE strname = iv_strnam.
      ls_item-vakey = ls_itmvakey.
      ls_item-qualif = <opt>-fieldname.
      ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE is_quellstr TO FIELD-SYMBOL(<value>).
      IF <value> IS ASSIGNED.
        WRITE <value> TO ls_item-fvalue.
      ELSE.
        ls_item-fvalue = 'NOT_ASSIGNED'.
      ENDIF.
      APPEND ls_item TO et_item.
      UNASSIGN <value>.

*     Bezeichnungen der Schlüsselfelder ausgeben
      CHECK <opt>-text = abap_true. " or ms_import-i_all_detail ne space.
      CASE <opt>-fieldname.
        WHEN 'PRDHA'.
*         Bezeichnung der Produkthierarchie je Level ermitteln und hinzufügen
          get_prodh_text( EXPORTING iv_fieldname = <opt>-fieldname
                                    iv_value     = ls_item-fvalue
                                    iv_vakey     = ls_item-vakey
                            CHANGING ct_values    = et_item ).

        WHEN OTHERS.
          get_description(
               EXPORTING
                      iv_tabname   = <opt>-strname
                      iv_fieldname = <opt>-fieldname
                      iv_value     = ls_item-fvalue
                      iv_vakey     = ls_item-vakey
              IMPORTING
                      es_values    = ls_itemt ).
*
          CHECK ls_itemt-fvalue NE space .

          APPEND ls_itemt TO et_item.


      ENDCASE.
    ENDLOOP.


  ENDMETHOD.
