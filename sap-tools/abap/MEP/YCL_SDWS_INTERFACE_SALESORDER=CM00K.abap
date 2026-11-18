  METHOD export_bapi_extensions.
    DATA: dref_itm   TYPE REF TO data.
    DATA: ls_item     TYPE ysdws_comitm_s,
          ls_header   TYPE ysdws_comhdr_s,
          ls_itmvakey TYPE ty_itmvakey.


    LOOP AT mt_extensionex ASSIGNING FIELD-SYMBOL(<itm>)
      WHERE structure = iv_strname.

      CREATE DATA dref_itm TYPE (<itm>-structure).
      ASSIGN dref_itm->* TO FIELD-SYMBOL(<wa>).
      MOVE <itm>+30 TO <wa>.

      IF iv_itmnumber IS NOT INITIAL.
        ASSIGN COMPONENT 'POSNR' OF STRUCTURE <wa> TO FIELD-SYMBOL(<posnr>).
        CHECK <posnr> IS ASSIGNED.
        CHECK iv_itmnumber = <posnr>.
        ls_itmvakey-itm_number = iv_itmnumber.
        ls_itmvakey-itm_obj = mc_item.
      ENDIF.
      LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
        WHERE strname = <itm>-structure.
        ls_item-vakey  = ls_itmvakey.
        ls_item-qualif = <opt>-fieldname.
        ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE <wa> TO FIELD-SYMBOL(<value>).
        IF <value> IS ASSIGNED.
          WRITE <value> TO ls_item-fvalue.
        ELSE.
          ls_item-fvalue = 'NOT_ASSIGNED'.
        ENDIF.
        IF ls_item-vakey IS INITIAL.
          MOVE-CORRESPONDING ls_item TO ls_header.
          APPEND ls_header TO es_salesorder-et_header.
        ELSE.
          APPEND ls_item TO es_salesorder-et_item.
        ENDIF.
        UNASSIGN <value>.
      ENDLOOP.

    ENDLOOP.


  ENDMETHOD.
