  METHOD export_bapi_schedules.


    DATA: ls_item     TYPE ysdws_comitm_s,
          ls_itmvakey TYPE ty_itmvakey.

    LOOP AT mt_order_schedules_ex ASSIGNING FIELD-SYMBOL(<item>)
     WHERE itm_number = iv_itmnumber.

      ls_itmvakey-itm_number = iv_itmnumber.
      ls_itmvakey-itm_obj = mc_sche.
      ls_itmvakey-itm_key = <item>-sched_line.
      ls_item-vakey = ls_itmvakey.
      LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
        WHERE strname = 'BAPISDHEDU'.

        ls_item-qualif = <opt>-fieldname.
        ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE <item> TO FIELD-SYMBOL(<value>).
        IF <value> IS ASSIGNED.
          WRITE <value> TO ls_item-fvalue.
        ELSE.
          ls_item-fvalue = 'NOT_ASSIGNED'.
        ENDIF.
        APPEND ls_item TO et_item.
        UNASSIGN <value>.
      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.
