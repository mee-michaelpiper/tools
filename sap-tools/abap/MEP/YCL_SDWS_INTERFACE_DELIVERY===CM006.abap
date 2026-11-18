  METHOD export_bapi_partner.

    DATA: ls_item      TYPE ysdws_comitm_s,
          ls_itmvakey  TYPE ty_itmvakey,
          ls_addr1_sel TYPE addr1_sel,
          ls_sadr      TYPE sadr.

    LOOP AT mt_vbpavb ASSIGNING FIELD-SYMBOL(<item>)
     WHERE posnr = iv_itmnumber.

      ls_itmvakey-itm_number = iv_itmnumber.
      ls_itmvakey-itm_obj = mc_part.
      ls_itmvakey-itm_key = <item>-parvw. " && iv_itmnumber.
      LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
        WHERE strname = 'VBPAVB'.

        CHECK ls_itmvakey-itm_key CS <opt>-vakey.

        ls_item-vakey = ls_itmvakey.
        ls_item-qualif = <opt>-fieldname.
        ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE <item> TO FIELD-SYMBOL(<value>).
        IF <value> IS ASSIGNED.
          WRITE <value> TO ls_item-fvalue.
        ELSE.
          ls_item-fvalue = 'NOT_ASSIGNED'.
        ENDIF.
        APPEND ls_item TO et_item.
        UNASSIGN <value>.
        CLEAR ls_item.
      ENDLOOP.

      CHECK sy-subrc EQ 0.
      "   CHECK ls_itmvakey-itm_key CS <opt>-vakey.


      READ TABLE mt_order_addr_ex WITH KEY adrnr = <item>-adrnr
       ASSIGNING FIELD-SYMBOL(<addr>).

      IF sy-subrc NE 0.

        ls_addr1_sel-addrnumber = <item>-adrnr.
        CALL FUNCTION 'ADDR_GET'
          EXPORTING
            address_selection = ls_addr1_sel
          IMPORTING
            sadr              = ls_sadr
          EXCEPTIONS
            parameter_error   = 1
            address_not_exist = 2
            version_not_exist = 3
            internal_error    = 4
            address_blocked   = 5
            OTHERS            = 6.

        APPEND INITIAL LINE TO mt_order_addr_ex ASSIGNING <addr>.
        MOVE-CORRESPONDING ls_sadr TO <addr>.
      ENDIF.


      LOOP AT mt_outputfields ASSIGNING <opt>
    WHERE strname = 'SADRVB'.

        CHECK ls_itmvakey-itm_key CS <opt>-vakey.

        ls_item-vakey = ls_itmvakey.
        ls_item-qualif = <opt>-fieldname.
        ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE <addr> TO <value>.
        IF <value> IS ASSIGNED.
          WRITE <value> TO ls_item-fvalue.
        ELSE.
          ls_item-fvalue = 'NOT_ASSIGNED'.
        ENDIF.
        APPEND ls_item TO et_item.
        UNASSIGN <value>.
        CLEAR ls_item.
      ENDLOOP.

    ENDLOOP.


  ENDMETHOD.
