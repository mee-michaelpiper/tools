METHOD EXPORT_BAPI_HEADER.

  DATA: ls_header     TYPE ysdws_comhdr_s,
        ls_itmvakey   TYPE ty_itmvakey.


  LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
    WHERE strname = iv_strnam.

    ls_header-qualif = <opt>-fieldname.
    ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE is_quellstr TO FIELD-SYMBOL(<value>).
    IF <value> IS ASSIGNED.
      WRITE <value> TO ls_header-fvalue.
    ELSE.
      ls_header-fvalue = 'NOT_ASSIGNED'.
    ENDIF.
    APPEND ls_header TO et_header.
      UNASSIGN <value>.
  ENDLOOP.


ENDMETHOD.
