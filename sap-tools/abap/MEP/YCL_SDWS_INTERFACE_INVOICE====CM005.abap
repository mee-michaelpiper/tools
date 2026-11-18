  METHOD export_bapi_header.

    DATA: ls_header   TYPE ysdws_comhdr_s,
          ls_itmvakey TYPE ty_itmvakey.


    LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
      WHERE strname = 'BAPISDHD'.

      ls_header-qualif = <opt>-fieldname.
      ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE ms_order_header_ex TO FIELD-SYMBOL(<value>).
      IF <value> IS ASSIGNED.
        WRITE <value> TO ls_header-fvalue.
      ELSE.
        ls_header-fvalue = 'NOT_ASSIGNED'.
      ENDIF.
      APPEND ls_header TO et_header.
      UNASSIGN <value>.
    ENDLOOP.


  ENDMETHOD.
